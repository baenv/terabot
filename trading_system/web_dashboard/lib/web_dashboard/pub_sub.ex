defmodule Web.PubSub do
  @moduledoc """
  A simple PubSub system that allows publishing and subscribing to topics.
  Uses the Phoenix.PubSub system under the hood.
  """

  @pubsub WebDashboard.PubSub

  @doc """
  Subscribes to a topic.
  """
  def subscribe(topic, fun) when is_function(fun, 1) do
    Phoenix.PubSub.subscribe(@pubsub, topic)
    # Store the callback in the process dictionary
    Process.put({__MODULE__, topic}, fun)
    :ok
  end

  @doc """
  Publishes a message to a topic.
  """
  def publish(topic, message) do
    Phoenix.PubSub.broadcast(@pubsub, topic, message)
    :ok
  end

  # In your process where subscribe/2 was called,
  # handle the callback with handle_info
  def handle_info(message, state) do
    topics = Process.get()
    |> Enum.filter(fn {{module, _topic}, _fun} -> module == __MODULE__ end)
    |> Enum.map(fn {{_module, topic}, fun} -> {topic, fun} end)

    # Call the callback for each topic the message matches
    Enum.each(topics, fn {topic, fun} ->
      fun.(message)
    end)

    {:noreply, state}
  end
end
