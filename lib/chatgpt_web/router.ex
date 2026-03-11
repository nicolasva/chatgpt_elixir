defmodule ChatgptWeb.Router do
  use ChatgptWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChatgptWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChatgptWeb do
    pipe_through :browser

    get "/", ChatController, :index
    post "/chat", ChatController, :chat
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChatgptWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:chatgpt, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChatgptWeb.Telemetry
    end
  end
end
