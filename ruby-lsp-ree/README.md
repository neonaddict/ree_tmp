# Ruby::Lsp::Ree

Ree addon for Ruby LSP

## How to use it:

1. Install Ruby LSP for your editor [link](https://github.com/Shopify/ruby-lsp?tab=readme-ov-file#getting-started)
2. Add `ree` gem into the Gemfile and run `bundle install`. Ruby LSP will detect the addon and run it.

If everything was installed successfully, you should see Ree in the list of Ruby LSP addons.
(In VS Code click `{}` brackets in the bottom right corner)

To use ree_formatter, add the following line into you `settings.json` file (e.g. `.vscode/settings.json`)
```json
"rubyLsp.formatter": "ree_formatter"
```

## Functions

- autocomplete for Ree functions
- autocomplete for constants
- adds links to the links section on autocomplete
- sort links on document save or format (with ree_formatter enabled)
- Go To Definition for Ree functions