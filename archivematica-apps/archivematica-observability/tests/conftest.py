def pytest_addoption(parser):
    parser.addoption(
        "--otel-config",
        help="Rendered Terraform collector JSON; enables the CloudWatch export tests.",
    )
