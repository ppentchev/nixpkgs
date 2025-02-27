{ buildGoModule
, fetchFromGitHub
, lib
, stdenv
, systemdMinimal
, withSystemd ? false
}:

buildGoModule rec {
  pname = "opentelemetry-collector-contrib";
  version = "0.76.1";

  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector-contrib";
    rev = "v${version}";
    sha256 = "sha256-Aeiq9IJReUxJUpeq5mSReK5foC5aY4fMSZli0ZUjYPc=";
  };
  # proxy vendor to avoid hash missmatches between linux and macOS
  proxyVendor = true;
  vendorSha256 = "sha256-vLbx/qmSZuteuvChnyA/wcEcIjU3zWkxSjfk8VBdgU4=";

  # there is a nested go.mod
  sourceRoot = "source/cmd/otelcontribcol";

  # CGO_ENABLED=0 required for mac - "error: 'TARGET_OS_MAC' is not defined, evaluates to 0"
  # https://github.com/shirou/gopsutil/issues/976
  CGO_ENABLED = if stdenv.isLinux then 1 else 0;

  # journalctl is required in-$PATH for the journald receiver tests.
  nativeCheckInputs = lib.optionals stdenv.isLinux [ systemdMinimal ];

  # We don't inject the package into propagatedBuildInputs unless
  # asked to avoid hard-requiring a large package. For the journald
  # receiver to work, journalctl will need to be available in-$PATH,
  # so expose this as an option for those who want more control over
  # it instead of trusting the global $PATH.
  propagatedBuildInputs = lib.optionals withSystemd [ systemdMinimal ];

  # This test fails on darwin for mysterious reasons.
  checkFlags = lib.optionals stdenv.isDarwin
    [ "-skip" "TestDefaultExtensions/memory_ballast" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/open-telemetry/opentelemetry-collector-contrib/internal/version.Version=v${version}"
  ];

  meta = with lib; {
    description = "OpenTelemetry Collector superset with additional community collectors";
    longDescription = ''
      The OpenTelemetry Collector offers a vendor-agnostic implementation on how
      to receive, process and export telemetry data. In addition, it removes the
      need to run, operate and maintain multiple agents/collectors in order to
      support open-source telemetry data formats (e.g. Jaeger, Prometheus, etc.)
      sending to multiple open-source or commercial back-ends. The Contrib
      edition provides aditional vendor specific receivers/exporters and/or
      components that are only useful to a relatively small number of users and
      is multiple times larger as a result.
    '';
    homepage = "https://github.com/open-telemetry/opentelemetry-collector-contrib";
    changelog = "https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/v${version}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ uri-canva jk ];
    mainProgram = "otelcontribcol";
  };
}
