import Config

config :logger, backends: [RingLogger]

config :graph_conn, :mock,
  capabilities: %{
    "ExecuteCommand" => %{
      "description" => "this one executes commands",
      "mandatoryParameters" => %{
        "command" => %{"description" => "command to execute"},
        "host" => %{"description" => "hostname to execute command on"}
      },
      "optionalParameters" => %{
        "timeout" => %{"default" => "120", "description" => "timeout in seconds"}
      }
    },
    "HTTPRequest" => %{
      "description" => "this one invokes HTTP call",
      "mandatoryParameters" => %{
        "method" => %{"default" => "GET", "description" => "HTTP method"},
        "url" => %{"description" => "url to hit"}
      },
      "optionalParameters" => %{
        "timeout" => %{"default" => "120", "description" => "timeout in seconds"}
      }
    },
    "ExecuteWindowsCommand" => %{
      "description" => "this one executes commands on crappy Windows machines",
      "mandatoryParameters" => %{
        "host" => %{"description" => "hostname to execute command on"},
        "command" => %{"description" => "command to execute (i.e. hostname)"}
      },
      "optionalParameters" => %{
        "command_type" => %{"default" => "cmd", "description" => "CMD or PS"},
        "arguments" => %{"default" => "", "description" => "optional argument list"},
        "timeout" => %{"default" => "120", "description" => "timeout in seconds"}
      }
    }
  },
  applicabilities: %{"action_handler" => %{}}
