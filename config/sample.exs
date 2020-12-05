import Config

config :orders_simulation,
  order_count: 36,
  shelves: [
    ["Hot", 4],
    ["Cold", 4],
    ["Frozen", 4],
    ["Overflow", 6]
  ]
