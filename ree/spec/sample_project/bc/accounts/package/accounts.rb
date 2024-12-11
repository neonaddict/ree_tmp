{
  "schema_type": "package",
  "schema_version": "1.1",
  "name": "accounts",
  "entry_path": "bc/accounts/package/accounts.rb",
  "tags": [
    "accounts",
    "account"
  ],
  "depends_on": [
    {
      "name": "clock"
    },
    {
      "name": "documents"
    },
    {
      "name": "errors"
    },
    {
      "name": "hash_utils"
    },
    {
      "name": "roles"
    },
    {
      "name": "test_utils"
    }
  ],
  "env_vars": [
    {
      "name": "accounts.integer_var",
      "doc": null
    },
    {
      "name": "accounts.string_var",
      "doc": null
    }
  ],
  "objects": [
    {
      "name": "account_serializer",
      "schema": "bc/accounts/schemas/accounts/account_serializer.schema.json",
      "tags": [
        "object"
      ]
    },
    {
      "name": "accounts",
      "schema": "bc/accounts/package/accounts.rb",
      "tags": [

      ]
    },
    {
      "name": "accounts_cfg",
      "schema": "bc/accounts/schemas/accounts/services/accounts_cfg.schema.json",
      "tags": [
        "object"
      ]
    },
    {
      "name": "build_user",
      "schema": "bc/accounts/schemas/accounts/services/build_user.schema.json",
      "tags": [
        "fn"
      ]
    },
    {
      "name": "build_user_spec",
      "schema": "bc/accounts/spec/accounts/services/build_user_spec.rb",
      "tags": [

      ]
    },
    {
      "name": "deliver_email",
      "schema": "bc/accounts/schemas/accounts/services/deliver_email.schema.json",
      "tags": [
        "fn"
      ]
    },
    {
      "name": "deliver_email_spec",
      "schema": "bc/accounts/spec/accounts/services/deliver_email_spec.rb",
      "tags": [

      ]
    },
    {
      "name": "entity",
      "schema": "bc/accounts/package/accounts/entities/entity.rb",
      "tags": [

      ]
    },
    {
      "name": "factory_users_repo",
      "schema": "bc/accounts/schemas/accounts/repo/factory_users_repo.schema.json",
      "tags": [
        "object"
      ]
    },
    {
      "name": "function",
      "schema": "bc/accounts/schemas/accounts/services/function.schema.json",
      "tags": [
        "fn"
      ]
    },
    {
      "name": "perform_async",
      "schema": "bc/accounts/schemas/accounts/services/perform_async.schema.json",
      "tags": [
        "fn"
      ]
    },
    {
      "name": "register_account_cmd",
      "schema": "bc/accounts/schemas/accounts/commands/register_account_cmd.schema.json",
      "tags": [
        "fn"
      ]
    },
    {
      "name": "spec_helper",
      "schema": "bc/accounts/spec/spec_helper.rb",
      "tags": [

      ]
    },
    {
      "name": "transaction",
      "schema": "bc/accounts/schemas/accounts/services/transaction.schema.json",
      "tags": [
        "fn"
      ]
    },
    {
      "name": "user",
      "schema": "bc/accounts/package/accounts/entities/user.rb",
      "tags": [

      ]
    },
    {
      "name": "user_states",
      "schema": "bc/accounts/schemas/accounts/enums/user_states.schema.json",
      "tags": [
        "object"
      ]
    },
    {
      "name": "users_repo",
      "schema": "bc/accounts/schemas/accounts/repo/users_repo.schema.json",
      "tags": [
        "object"
      ]
    },
    {
      "name": "welcome_email",
      "schema": "bc/accounts/schemas/accounts/emails/welcome_email.schema.json",
      "tags": [
        "object"
      ]
    }
  ]
}