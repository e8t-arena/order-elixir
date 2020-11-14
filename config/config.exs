import Config

config :orders_simulation,
  order_rate: 2, # per second
  order_interval: 1, # seconds
  shelves: [
    ["Hot", 10],
    ["Cold", 10],
    ["Frozen", 10],
    ["Overflow", 15]
  ]

import_config "#{config_env()}.exs"
