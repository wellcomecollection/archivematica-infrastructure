"""Protect the complete Wellcome branch of the Storage Service migrations.

The overlay adds Wellcome migrations alongside the migrations in the pinned
upstream revision. ``UPSTREAM_LEAF`` identifies the end of the upstream-only
branch, while ``WELLCOME_MIGRATION_DEPENDENCIES`` is the explicit manifest of
everything added by the overlay.

When the upstream base or Wellcome branch changes, update both declarations.
The tests will reject unclassified migrations, changed dependencies, multiple
leaves, unapplied migrations, and merge migrations that contain operations.
"""

import pytest
from django.contrib.auth.models import Group
from django.db import connection
from django.db.migrations.loader import MigrationLoader

APP_LABEL = "locations"
UPSTREAM_LEAF = (APP_LABEL, "0037_django42")
WELLCOME_LEAF = (APP_LABEL, "0040_add_wellcome_manager_permissions")

WELLCOME_MIGRATION_DEPENDENCIES = {
    "0026_wellcome": {(APP_LABEL, "0025_update_package_size")},
    "0027_add_wellcome_callback_fields": {(APP_LABEL, "0026_wellcome")},
    "0028_wellcome_blank_aws_auth": {(APP_LABEL, "0027_add_wellcome_callback_fields")},
    "0029_auto_20200122_0726": {(APP_LABEL, "0028_wellcome_blank_aws_auth")},
    "0031_merge_20221017_0727": {
        (APP_LABEL, "0029_auto_20200122_0726"),
        (APP_LABEL, "0030_user_groups"),
    },
    "0034_merge_20230720_0400": {
        (APP_LABEL, "0031_merge_20221017_0727"),
        (APP_LABEL, "0033_package_checksum"),
    },
    "0038_merge_20250527_1404": {
        (APP_LABEL, "0034_merge_20230720_0400"),
        (APP_LABEL, "0037_django42"),
    },
    "0039_alter_space_access_protocol": {(APP_LABEL, "0038_merge_20250527_1404")},
    "0040_add_wellcome_manager_permissions": {
        (APP_LABEL, "0039_alter_space_access_protocol")
    },
}

MERGE_MIGRATIONS = {
    "0031_merge_20221017_0727",
    "0034_merge_20230720_0400",
    "0038_merge_20250527_1404",
}

pytestmark = pytest.mark.django_db


@pytest.fixture
def migration_loader():
    """Load the migration graph and applied state from pytest's database."""
    return MigrationLoader(connection)


def test_wellcome_migration_graph_is_complete(migration_loader):
    """Require the installed graph to match the declared Wellcome branch.

    Subtracting every ancestor of the pinned upstream leaf from all installed
    ``locations`` migrations leaves exactly the migrations added by the
    overlay. Their dependencies must match the manifest, and together they
    must produce one conflict-free leaf.
    """
    upstream_migrations = {
        node
        for node in migration_loader.graph.forwards_plan(UPSTREAM_LEAF)
        if node[0] == APP_LABEL
    }
    installed_migrations = {
        node for node in migration_loader.disk_migrations if node[0] == APP_LABEL
    }
    expected_wellcome_migrations = {
        (APP_LABEL, name) for name in WELLCOME_MIGRATION_DEPENDENCIES
    }

    assert installed_migrations - upstream_migrations == expected_wellcome_migrations
    assert set(migration_loader.graph.leaf_nodes(APP_LABEL)) == {WELLCOME_LEAF}
    assert not migration_loader.detect_conflicts().get(APP_LABEL)

    for name, expected_dependencies in WELLCOME_MIGRATION_DEPENDENCIES.items():
        migration = migration_loader.disk_migrations[(APP_LABEL, name)]
        assert set(migration.dependencies) == expected_dependencies


def test_wellcome_migrations_are_applied(migration_loader):
    """Require every declared Wellcome migration to be applied successfully."""
    migration_loader.check_consistent_history(connection)
    expected_wellcome_migrations = {
        (APP_LABEL, name) for name in WELLCOME_MIGRATION_DEPENDENCIES
    }

    assert expected_wellcome_migrations <= set(migration_loader.applied_migrations)


def test_wellcome_merge_migrations_have_no_operations(migration_loader):
    """Keep merge migrations as dependency joins without schema or data work."""
    for name in MERGE_MIGRATIONS:
        migration = migration_loader.disk_migrations[(APP_LABEL, name)]
        assert not migration.operations


def test_managers_have_wellcome_storage_service_permissions():
    """Confirm the post-merge data migration grants all model permissions."""
    manager = Group.objects.get(name="Managers")
    permissions = manager.permissions.filter(
        content_type__app_label=APP_LABEL,
        content_type__model="wellcomestorageservice",
    )

    assert set(permissions.values_list("codename", flat=True)) == {
        "add_wellcomestorageservice",
        "change_wellcomestorageservice",
        "delete_wellcomestorageservice",
        "view_wellcomestorageservice",
    }
