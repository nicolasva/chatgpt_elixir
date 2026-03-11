defmodule Chatgpt.Repo do
  use Ecto.Repo,
    otp_app: :chatgpt,
    adapter: Ecto.Adapters.Postgres
end
