defmodule Dantzig.Application do
  @moduledoc false
  use Application

  alias Dantzig.HiGHSDownloader

  def start(_type, _args) do
    # Download the solver binary if it doesn't exist yet
    HiGHSDownloader.maybe_download_for_target()
    # Start an empty application
    Supervisor.start_link([], strategy: :one_for_one)
  end
end
