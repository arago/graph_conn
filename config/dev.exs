import Config

config :logger, backends: [RingLogger]

config :graph_conn, :mock,
  capabilities: %{
    "ExecuteLocalCommand" => %{
      "description" => "this one executes commands on the same machine where AH is running",
      "mandatoryParameters" => %{
        "command" => %{"description" => "command to execute"}
      },
      "optionalParameters" => %{
        "timeout" => %{"default" => "5", "description" => "timeout in seconds"}
      }
    },
    "ExecuteWindowsCommand" => %{
      "description" => "this one executes commands on crappy Windows machines",
      "mandatoryParameters" => %{
        "host" => %{"description" => "hostname to execute command on"},
        "transport" => %{"default" => "ssl", "description" => "ssl or plain"},
        "command_type" => %{"default" => "cmd", "description" => "command type CMD or PS"},
        "command" => %{"description" => "command to execute"}
      },
      "optionalParameters" => %{
        "timeout" => %{"default" => "120", "description" => "timeout in seconds"}
      }
    },
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
    }
  },
  applicabilities: %{"action_handler" => %{}}
