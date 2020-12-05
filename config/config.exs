import Config

config :orders_simulation,
  order_rate: 2, # per second
  order_interval: 1, # seconds
  order_count: :all,
  shelves: [
    ["Hot", 10],
    ["Cold", 10],
    ["Frozen", 10],
    ["Overflow", 15]
  ]

config :logger,
  backends: [:console]

config :logger, :console,
  level: :info,
  format: "\n##### $date $time $metadata[$level] $levelpad$message\n"
  # metadata: :all

import_config "#{config_env()}.exs"
