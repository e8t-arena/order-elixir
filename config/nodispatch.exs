import Config

config :orders_simulation,
  order_count: 36,
  no_dispatch: true,
  shelves: [
    ["Hot", 4],
    ["Cold", 4],
    ["Frozen", 4],
    ["Overflow", 6]
  ]
