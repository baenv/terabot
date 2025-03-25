defmodule Core.Vault.KeyVault do
  @moduledoc """
  Secure storage for private keys and other sensitive credentials.
  Uses strong encryption to protect keys at rest.
  """
  
  use GenServer
  require Logger
  
  # Client API
  
  @doc """
  Starts the key vault process.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Stores an encrypted private key for an account.
  
  ## Parameters
    * `account_id` - The ID of the account
    * `private_key` - The private key to store (plaintext)
    * `encryption_password` - Password used for encryption
  
  Returns:
    * `{:ok, key_id}` - The ID of the stored key
    * `{:error, reason}` - Error with reason
  """
  def store_private_key(account_id, private_key, encryption_password) do
    GenServer.call(__MODULE__, {:store_private_key, account_id, private_key, encryption_password})
  end
  
  @doc """
  Retrieves a private key for an account.
  
  ## Parameters
    * `account_id` - The ID of the account
    * `encryption_password` - Password used for decryption
  
  Returns:
    * `{:ok, private_key}` - The decrypted private key
    * `{:error, reason}` - Error with reason
  """
  def get_private_key(account_id, encryption_password) do
    GenServer.call(__MODULE__, {:get_private_key, account_id, encryption_password})
  end
  
  @doc """
  Checks if a private key exists for an account.
  
  ## Parameters
    * `account_id` - The ID of the account
  
  Returns:
    * `true` - Private key exists
    * `false` - Private key does not exist
  """
  def has_private_key?(account_id) do
    GenServer.call(__MODULE__, {:has_private_key, account_id})
  end
  
  @doc """
  Removes a private key for an account.
  
  ## Parameters
    * `account_id` - The ID of the account
  
  Returns:
    * `:ok` - Private key was removed
    * `{:error, reason}` - Error with reason
  """
  def remove_private_key(account_id) do
    GenServer.call(__MODULE__, {:remove_private_key, account_id})
  end
  
  # Server callbacks
  
  @impl GenServer
  def init(_opts) do
    # Initialize the vault storage
    # In a production environment, this would use a secure storage backend
    # For development, we'll use an in-memory map with encryption
    {:ok, %{keys: %{}}}
  end
  
  @impl GenServer
  def handle_call({:store_private_key, account_id, private_key, encryption_password}, _from, state) do
    # Encrypt the private key
    case encrypt_private_key(private_key, encryption_password) do
      {:ok, encrypted_key} ->
        # Store the encrypted key
        key_id = generate_key_id()
        keys = Map.put(state.keys, account_id, %{
          id: key_id,
          encrypted_key: encrypted_key,
          created_at: DateTime.utc_now()
        })
        
        Logger.info("Stored encrypted private key for account #{account_id}")
        {:reply, {:ok, key_id}, %{state | keys: keys}}
        
      {:error, reason} ->
        Logger.error("Failed to encrypt private key: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
  
  @impl GenServer
  def handle_call({:get_private_key, account_id, encryption_password}, _from, state) do
    case Map.get(state.keys, account_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
        
      key_data ->
        # Decrypt the private key
        case decrypt_private_key(key_data.encrypted_key, encryption_password) do
          {:ok, private_key} ->
            {:reply, {:ok, private_key}, state}
            
          {:error, reason} ->
            Logger.error("Failed to decrypt private key: #{reason}")
            {:reply, {:error, reason}, state}
        end
    end
  end
  
  @impl GenServer
  def handle_call({:has_private_key, account_id}, _from, state) do
    has_key = Map.has_key?(state.keys, account_id)
    {:reply, has_key, state}
  end
  
  @impl GenServer
  def handle_call({:remove_private_key, account_id}, _from, state) do
    keys = Map.delete(state.keys, account_id)
    Logger.info("Removed private key for account #{account_id}")
    {:reply, :ok, %{state | keys: keys}}
  end
  
  # Private functions
  
  defp generate_key_id do
    # Generate a unique ID for the key
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
  
  defp encrypt_private_key(private_key, password) do
    # In a production environment, use a strong encryption library
    # For this example, we'll use a simple AES encryption
    
    try do
      # Generate a random IV
      iv = :crypto.strong_rand_bytes(16)
      
      # Derive a key from the password
      key = :crypto.hash(:sha256, password)
      
      # Encrypt the private key
      encrypted = :crypto.crypto_one_time(:aes_256_cbc, key, iv, pad_message(private_key), true)
      
      # Combine IV and encrypted data
      {:ok, Base.encode64(iv <> encrypted)}
    rescue
      e ->
        {:error, "Encryption failed: #{inspect(e)}"}
    end
  end
  
  defp decrypt_private_key(encrypted_key, password) do
    try do
      # Decode the combined IV and encrypted data
      decoded = Base.decode64!(encrypted_key)
      
      # Extract IV and encrypted data
      <<iv::binary-size(16), encrypted::binary>> = decoded
      
      # Derive a key from the password
      key = :crypto.hash(:sha256, password)
      
      # Decrypt the private key
      decrypted = :crypto.crypto_one_time(:aes_256_cbc, key, iv, encrypted, false)
      
      # Unpad the decrypted message
      {:ok, unpad_message(decrypted)}
    rescue
      e ->
        {:error, "Decryption failed: #{inspect(e)}"}
    end
  end
  
  defp pad_message(message) do
    # PKCS#7 padding
    pad_length = 16 - rem(byte_size(message), 16)
    message <> :binary.copy(<<pad_length>>, pad_length)
  end
  
  defp unpad_message(padded_message) do
    # PKCS#7 unpadding
    <<pad_length>> = binary_part(padded_message, byte_size(padded_message) - 1, 1)
    binary_part(padded_message, 0, byte_size(padded_message) - pad_length)
  end
end
