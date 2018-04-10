# sQucumber Postgres

[![Build Status](https://travis-ci.org/moertel/sQucumber-postgres.svg)](https://travis-ci.org/moertel/sQucumber-postgres) [![Gem Version](https://badge.fury.io/rb/squcumber-postgres.svg)](https://badge.fury.io/rb/squcumber-postgres)

Bring the BDD approach to writing SQL for your Postgres instance and be confident that your scripts do what they're supposed to do. Define and execute SQL unit, acceptance and integration tests and let them serve as a living documentation for your queries. It's Cucumber - for SQL!

 * [Example](#example)
 * [How it works](#how-it-works)
 * [Installation](#installation)
 * [Usage](#usage)
   * [Environment variables](#environment-variables)
 * [Step definitions](#available-steps)

## Example

Suppose you want to test that `kpi_reporting.sql` is producing correct results; its `.feature` file could look as follows:
```cucumber
# features/kpi_reporting.feature

Feature: KPI Reporting

  Scenario: There are some visitors and some orders
    Given the existing table "access_logs":
      | req_date   | req_time | request_id |
      | 2016-07-29 | 23:45:16 | 751fa12d-c51e-4823-8362-f85fde8b7fcd |
      | 2016-07-31 | 22:13:54 | 35c4699e-c035-44cb-957c-3cd992b0ad73 |
      | 2016-07-31 | 11:23:45 | 0000021d-7e77-4748-89f5-cddd0a11d2f9 |
    And the existing table "orders":
      | order_date | product |
      | 2016-07-31 | Premium |
    When the SQL file "kpi_reporting.sql" is executed
    And the resulting table "kpi_reporting" is queried
    Then the result exactly matches:
      | date       | visitors | orders |
      | 2016-07-29 | 1        | 0      |
      | 2016-07-31 | 2        | 1      |
```

## How It Works

Feature files are written in the <a href="https://github.com/cucumber/cucumber/wiki/Gherkin" target="_blank">Gherkin language</a>. A feature, such as an SQL file, consists of several scenarios. A scenario describes how the script behaves under some particular conditions which are outlined using <a href=https://github.com/cucumber/cucumber/wiki/Given-When-Then>**Given - When - Then**</a> steps.

Under the hood, sQucumber connects to your Postgres instance, creates a new database (prefixed with `test_env_` followed by a random number) and copies over the schemas and tables you specify in the `Given` steps. The advantage of this is that you always test against the current live version of your database. If your script can be executed here, it is guaranteed to be able to be executed in production. With further `Then` steps you'll add mock data. Other than with actual live data, mocked table data gives you the freedom to define edge cases exactly as you like, even if they don't (yet) exist in production.

The `When` steps execute your SQL files and fetch their results. These can now be compared against expectations as specified in the `Then` steps. Whether you expect an empty result, want to check for the occurrence of partial results or make sure that actual and expected output match _exactly_, everything's possible.

Should a scenario fail, the differences between the expected and actual results will be displayed clearly, so you can fix your SQL script accordingly. Optionally, an HTML file with the test results is created, that can serve as a living documentation that can be passed on to stakeholders who want to use the script and understand how it works.

A full specification of all the available `Given - When - Then` steps can be found [here](#available-steps).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'squcumber-postgres'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install squcumber-postgres

## Usage

Put your `.feature` files in the directory `feature` in your project's root. (You may use subfolders.)
In order to take advantage of auto-generated Rake tasks, add this to your `Rakefile`:
```ruby
require 'squcumber-postgres/rake/task'
```

The following folder structure
```
└── features
    ├── marketing
    │   ├── sales.feature
    │   └── kpi.feature
    └── development
        └── logs
            └── aggregate.feature
```
Leads to the following Rake tasks:
```
$ rake -T
rake test:sql:marketing                                         # Run SQL tests for all features in marketing
rake test:sql:marketing:sales[scenario_line_number]             # Run SQL tests for feature marketing/sales
rake test:sql:marketing:kpi[scenario_line_number]               # Run SQL tests for feature marketing/kpi
rake test:sql:development                                       # Run SQL tests for all features in development
rake test:sql:development:logs                                  # Run SQL tests for all features in development/logs
rake test:sql:development:logs:aggregate[scenario_line_number]  # Run SQL tests for feature development/logs/aggregate
```

Run a whole suite of features by executing a Rake task on the folder level:
```
rake test:sql:marketing
```

Or execute a specific scenario only by specifying its line number in the corresponding `.feature` file:
```
rake test:sql:marketing:sales[12]
```

### Docker

Instead of installing the Gem in your project, you can run the SQL tests inside a Docker container. There's an automated build for [`moertel/squcumber-postgres`](https://hub.docker.com/r/moertel/squcumber-postgres/) tagged with the releases of the Gem. Alternatively, you can use the version from the `master` branch with the `latest` tag. To run the tests, mount your SQL and feature files into the container and provide the environment variables to access your Postgres database:

```bash
docker run \
  -v /local/path/to/sql:/sql \
  -v /local/path/to/features:/features \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=someuser \
  -e DB_PASSWORD=secret \
  -e DB_NAME=somedb \
  -it moertel/squcumber-postgres:latest
```

### Environment Variables

Make sure the following environment variables are set when running sQucumber's Rake tasks:

| Name | Description |
| ---- | ----------- |
| DB_HOST | Hostname of the Postgres instance |
| DB_PORT | Postgres port to connect to |
| DB_USER | Name of the Postgres user to use to create a testing database, must be a superuser |
| DB_PASSWORD | Password of the Postgres user |
| DB_NAME | Name of the DB on the Postgres instance |

Optional environment variables:

| Name | Value | Description | Default |
| ---- | ----- | ----------- | ------- |
| SPEC_SHOW_STDOUT | 1 | Show output of statements executed on the Postgres instance | 0 |
| KEEP_TEST_DB | 1 | Do not drop the database after test execution (useful for manual inspection) | 0 |
| TEST_DB_NAME_OVERRIDE | _String_ | Define a custom name for the testing database created on the instance. Setting this to `foo` will result in the database `test_env_foo` being created | random 5-digit integer |


## Available Steps
### `Given the SQL files in the path "{path}"`
  * Allows to add the `path` to SQL scripts that need to be executed to produce the result set<br/>
    Path can be either relative to the project root or absolute<br/>
    Files are executed in the order they are given, using [`When the given SQL files are executed`](#when-the-given-sql-files-are-executed)<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    For the files `project/src/sql/some_query.sql` and `project/src/sql/some_query.sql`:

    ```cucumber
    Given the SQL files in the path "project/src/sql":
      | file              |
      | some_query.sql    |
      | another_query.sql |
    When the given SQL files are executed
    And the resulting table "some_schema.some_table" is queried
    Then the result is empty
    ```
    </p>
    </details>

---

### `Given the SQL file path "{path}"`
  * Allows to add the `path` to SQL scripts that need to be executed during the steps<br/>
    Path can be either relative to the project root or absolute<br/>
    Works the same as [`Given the SQL files in the path "{path}"`](#given-the-sql-files-in-the-path-path) but doesn't take a list of queries<br/>
    Scripts can be executed on a per-file basis using [`When the SQL file "{file}" is executed`](#when-the-sql-file-file_name-is-executed)<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    For the path `project/src/sql`:

    ```cucumber
    Given the SQL file path "project/src/sql"
    When the SQL file "some_file.sql" is executed
    And the resulting table "some_schema.some_table" is queried
    Then result exactly matches:
      | some_column | another_column |
      | foo         | bar            |
    ```
    </p>
    </details>

---

### `Given their table dependencies`
  * Tables used by the SQL script(s). As the testing framework operates on a new, empty database, this makes sure that all dependencies are present upon script execution. Initially, tables defined here will be empty. You can add data to them by using the step [`Given the existing table "{schema_and_table}"`](#given-the-existing-table-schema_and_table)<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    Given the SQL files in the path "project/src/sql":
      | file      |
      | query.sql |
    And their table dependencies:
      | table                  |
      | some_schema.some_table |
    When the given SQL files are executed
    And the resulting table "some_schema.another_table" is queried
    Then the result exactly matches:
      | some_column | another_column |
      | foo         | bar            |
    ```
    </p>
    </details>

---

### `Given their schema dependencies`
  * Schemas used by the SQL scripts if not already specified by the step [`Given their table dependencies`](#given-their-table-dependencies). This step usually makes sense if your script wants to write data to an own schema.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    Given the SQL files in the path "project/src/sql":
      | file      |
      | query.sql |
    And their table dependencies:
      | table                  |
      | some_schema.some_table |
    And their schema dependencies:
      | schema         |
      | another_schema |
    When the given SQL files are executed
    And the resulting table "another_schema.some_table" is queried
    Then the result exactly matches:
      | some_column | another_column |
      | foo         | bar            |
    ```
    </p>
    </details>

---

### `Given the following defaults for "{schema_and_table}" (if not stated otherwise)`
  * Allows to set default values for particular table columns. This is useful if values are not allowed to be `NULL` but would clutter test scenarios or make tables very wide. Default values can always be overwritten in test steps. This step makes most sense as a `Background` step.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    Background:
      Given the following defaults for "some_schema.some_table" (if not stated otherwise):
        | some_column | another_column |
        | foo         | bar            |

    Scenario:
      Given the SQL files in the path "project/src/sql":
        | file      |
        | query.sql |
      And their table dependencies:
        | table                  |
        | some_schema.some_table |
      And the existing table "some_schema.some_table":
        | yet_another_column |
        | 123                |
      When the given SQL files are executed
      And the resulting table "another_schema.some_table" is queried
      Then the result exactly matches:
        | some_column | another_column |
        | foo         | bar            |
    ```
    </p>
    </details>

---

### `Given a clean environment`
  * Truncates all tables currently present in the database. This is usually called implicitly before a new scenario is executed.<br/>

---

### `Given the existing table "{schema_and_table}":`
  * Allows to insert data into the database. You only need to specify the columns that your SQL script relies on. All other column values will be set to `NULL`. Specifying a column but leaving the value empty will also result in a `NULL` value. All constraints and defaults are removed from the mock database, so it's your responsibility to ensure data integrity.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    Background:
      Given the SQL files in the path "project/src/sql":
        | file      |
        | query.sql |
      And their table dependencies:
        | table                  |
        | some_schema.some_table |

    Scenario:
      Given the existing table "some_schema.some_table":
        | some_column | another_column |
        | 123         | foo            |
        | 345         |                |
        |             | bar            |
      When the given SQL files are executed
      And the resulting table "some_schema.another_table" is queried
      Then the result exactly matches:
        | foo_count | bar_count |
        | 1         | 0         |
    ```
    </p>
    </details>

---

### `When the given SQL files are executed`
  * Takes all files provided in the [`Given the SQL files in the path "{path}"`](#given-the-sql-files-in-the-path-path) step and executes them in the specified order.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `When the SQL file "{file_name}" is executed`
  * Executes the given file at `{file_name}`. This can be an absolute file path or relative to the project root. If a path has been specified in the [`Given the SQL file path {path}`](#given-the-sql-file-path-path) step, it will be respected.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `When the resulting table "{schema_and_table}" is queried`
  * Fetches the contents of the table specified in `{schema_and_table}`. Note that the result is not necessarily ordered, so in case you expect more than one row and want to compare that a table matches _exactly_, consider ordering the result with the [`When the resulting table "{schema_and_table}" is queried, ordered by "{column_name}"`](#when-the-resulting-table-schema_and_table-is-queried-ordered-by-column_name) step.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `When the resulting table "{schema_and_table}" is queried, ordered by "{column_name}"`
  * Fetches the contents of the table specified in `{schema_and_table}` and orders the result by the `{column_name}` given. This is useful when the result is expected to match _exactly_ a particular result because rows will in this case be compared one by one in the given order.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `Then the result starts with`
  * Checks the results of the [`When the resulting table "{schema_and_table}" is queried`](#when-the-resulting-table-schema_and_table-is-queried) step and compares only the first row. An optional explanation can be added at the end, to make clear what is expected in the result.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `Then the result includes`
  * Checks the results of the [`When the resulting table "{schema_and_table}" is queried`](#when-the-resulting-table-schema_and_table-is-queried) step and makes sure the given expected rows do occur in the actual result, in any order. An optional explanation can be added at the end to clarify what is expected in the result.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `The result does not include`
  * Checks the results of the [`When the resulting table "{schema_and_table}" is queried`](#when-the-resulting-table-schema_and_table-is-queried) step and makes sure the given rows do not occur in the actual result. An optional explanation can be added at the end to clarify what is expected in the result.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `The result exactly matches`
  * Checks the results of the [`When the resulting table "{schema_and_table}" is queried`](#when-the-resulting-table-schema_and_table-is-queried) step and makes sure the given rows exactly match the actual result. Ordering is not important. An optional explanation can be added at the end to clarify what is expected in the result.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

### `Then the result is empty`
  * Checks that the results of the [`When the resulting table "{schema_and_table}" is queried`](#when-the-resulting-table-schema_and_table-is-queried) step is empty. An optional explanation can be added at the end to clarify what is expected in the result.<br/>
    <details><summary> <b>Example</b> (click to expand) </summary><p>

    ```cucumber
    ```
    </p>
    </details>

---

## Contributing

1. Fork it ( https://github.com/moertel/squcumber-postgres/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
