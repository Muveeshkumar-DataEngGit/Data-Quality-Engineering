import great_expectations as gx

# -----------------------------------------------------------------------------
# CONTEXT
# -----------------------------------------------------------------------------

context = gx.get_context()

# -----------------------------------------------------------------------------
# DATASOURCE
# -----------------------------------------------------------------------------

datasource = context.data_sources.add_snowflake(
    name="ZB55325",
    account="YXIFNZY-ZB55325",
    user="MUVEESHSHANMUGAM23",
    password="MUVEE@23devamanohari",
    database="MICRO_PART_LEARN",
    schema="MP_DEMO",
    warehouse="COMPUTE_WH",
    role="ACCOUNTADMIN"
)

# -----------------------------------------------------------------------------
# TABLE ASSET
# -----------------------------------------------------------------------------

asset = datasource.add_table_asset(
    name="sales_asset",
    table_name="SALES_DQ_DEMO"
)

batch_definition = asset.add_batch_definition_whole_table(
    "full_table"
)

batch = batch_definition.get_batch()

# -----------------------------------------------------------------------------
# EXPECTATION SUITE
# -----------------------------------------------------------------------------

suite = gx.ExpectationSuite(
    name="sales_dq_suite"
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToNotBeNull(
        column="SALE_ID"
    )
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToBeUnique(
        column="SALE_ID"
    )
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToBeInSet(
        column="REGION",
        value_set=[
            "CENTRAL",
            "WEST",
            "EAST",
            "NORTH",
            "SOUTH"
        ]
    )
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToNotBeNull(
        column="SALES_AMOUNT"
    )
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToBeBetween(
        column="SALES_AMOUNT",
        min_value=0,
        max_value=1000000
    )
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToBeBetween(
        column="QUANTITY",
        min_value=1,
        max_value=10000
    )
)

suite.add_expectation(
    gx.expectations.ExpectColumnValuesToNotBeNull(
        column="SALE_DATE"
    )
)

suite.add_expectation(
    gx.expectations.ExpectTableRowCountToBeBetween(
        min_value=1
    )
)

context.suites.add(suite)

# -----------------------------------------------------------------------------
# VALIDATION DEFINITION
# -----------------------------------------------------------------------------

validation_definition = gx.ValidationDefinition(
    name="sales_validation",
    data=batch_definition,
    suite=suite
)

context.validation_definitions.add(
    validation_definition
)

# -----------------------------------------------------------------------------
# CHECKPOINT
# -----------------------------------------------------------------------------

checkpoint = gx.Checkpoint(
    name="sales_checkpoint",
    validation_definitions=[
        validation_definition
    ]
)

context.checkpoints.add(checkpoint)

# -----------------------------------------------------------------------------
# RUN CHECKPOINT
# -----------------------------------------------------------------------------

print("\n" + "=" * 80)
print("RUNNING CHECKPOINT")
print("=" * 80)

checkpoint_result = checkpoint.run()

print(
    f"Validation Status : "
    f"{'PASS' if checkpoint_result.success else 'FAIL'}"
)

# -----------------------------------------------------------------------------
# DATA DOCS
# -----------------------------------------------------------------------------

print("\nBuilding Data Docs...")

context.build_data_docs()

print("\nDATA DOCS GENERATED SUCCESSFULLY")

for site in context.get_docs_sites_urls():
    print(
        f"Site Name : {site['site_name']}"
    )
    print(
        f"Site URL  : {site['site_url']}"
    )

print("\n" + "=" * 80)
print("CHECKPOINT COMPLETED")
print("=" * 80)