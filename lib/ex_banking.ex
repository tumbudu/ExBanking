defmodule ExBanking do

  @name :ex_banking

  use GenServer
  import ExUser



  @moduledoc """
    Application interface is just set of public functions of ExBanking module
    (no API endpoint, no REST / SOAP API, no TCP / UDP sockets, no any external network interface).
  """

  def start(_type, _args)  do
    start()
  end


  @doc """
    Start gen server
  """
  def start do
    GenServer.start(__MODULE__, [], name: @name)
  end

  def start_link(_Arg) do
    GenServer.start_link(__MODULE__, [], [])
  end


  @doc """
    Create user

    Function creates new user in the system
    New user has zero balance of any currency

    ## Parameters
      - name: String that represents the name of the person in system

    ## Output
      - :ok: Successfully user added to the system
      - {:error, :wrong_arguments}: When name argument is valid.
      - {:error, :user_already_exists}: When user alredy exist in system
  """
  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(name) when is_binary(name) do
    GenServer.call(@name, {:create_user, name});
  end

  def create_user(_name) do
    {:error, :wrong_arguments}
  end



  @doc """
    Get balance

    - Returns balance of the user in given format

    ## Parameters
      - name: String that user for which amount should be returned.
      - currency: String that represents the currency of the amount.

    ## Output
      - {:ok, balance} Success, balance returned for specified currency.
      - {:error, :wrong_arguments} Failuer, when arguments are not in currect format.
      - {:error, :user_does_not_exist} Failuer, when user does not exist in system.
      - {:error, :too_many_requests_to_user} Failuer, when number of api calls to user are not less than 10.
  """
  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(name, currency) when is_binary(name) and is_binary(currency) do
    cast({name, {:get_balance, currency}})
  end

  def get_balance(_name, _currency) do
    {:error, :wrong_arguments}
  end



  @doc """
    Deposit amount

    - Increases user’s balance in given currency by amount value.
    - Returns new_balance of the user in given format.

    ## Parameters
      - name: String that user for which amount should be deposited.
      - amount: Number that represents amount that should be deposited.
      - currency: String that represents the currency of the amount.

    ## Output
      - {:ok, new_balance} Success and new balance returned.
      - {:error, :wrong_arguments} Failuer, when arguments are not in currect format.
      - {:error, :user_does_not_exist} Failuer, when user does not exist in system.
      - {:error, :too_many_requests_to_user} Failuer, when number of api calls to user are not less than 10.
  """
  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(name, amount, currency) when is_binary(name) and is_number(amount) and is_binary(currency) and amount > 0 do
    cast({name, {:deposit, amount, currency}})
  end

  def deposit(_name, _amount, _currency) do
    {:error, :wrong_arguments}
  end



  @doc """
    Withdraw amount

    - Decreases user’s balance in given currency by amount value.
    - Returns new_balance of the user in given format.

    ## Parameters
      - name: String that user for which amount should be withdrawn.
      - amount: Number that represents amount that should be withdrawn.
      - currency: String that represents the currency of the amount.

    ## Output
      - {:ok, new_balance} Success and new balance returned.
      - {:error, :wrong_arguments} Failuer, when arguments are not in currect format.
      - {:error, :user_does_not_exist} Failuer, when user does not exist in system.
      - {:error, :not_enough_money} Failuer, when not enough balance in user's account.
      - {:error, :too_many_requests_to_user} Failuer, when number of api calls to user are not less than 10.
  """
  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user}
  def withdraw(name, amount, currency) when is_binary(name) and is_number(amount) and is_binary(currency) and amount > 0 do
    cast({name, {:withdraw, amount, currency}})
  end

  def withdraw(_name, _amount, _currency) do
    {:error, :wrong_arguments}
  end


  @doc """
    Send amount

    - Decreases from_user’s balance in given currency by amount value.
    - Increases to_user’s balance in given currency by amount value.
    - Returns balance of from_user and to_user in given format.

    ## Parameters

    ## Output
      - {:ok, from_user_balance, to_user_balance} Success, amount transferd from from_user to to_user.
      - {:error, :wrong_arguments}
      - {:error, :not_enough_money}
      - {:error, :sender_does_not_exist}
      - {:error, :receiver_does_not_exist}
      - {:error, :too_many_requests_to_sender}
      - {:error, :too_many_requests_to_receiver}
  """
  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | {:error, :wrong_arguments | :not_enough_money | :sender_does_not_exist | :receiver_does_not_exist | :too_many_requests_to_sender | :too_many_requests_to_receiver}
  def send(fromUser, toUser, amount, currency) when is_binary(fromUser) and is_binary(toUser) and is_number(amount) and is_binary(currency) and amount > 0 do
    cast({:send, fromUser, toUser, amount, currency})
  end

  def send(_fromUser, _toUser, _amount, _currency) do
    {:error, :wrong_arguments}
  end






  # @doc """
  #   Private function to revert withdrawal in case of failed to complete send operation

  #   ## Parameters
  #     - name : name of account holder
  #     - amount : amout to depost
  #     - currency : currency of the amount

  #   ## Output
  #     - {:error, reason} : reason for which revert withdrawal is happening
  # """
  defp revert_withdrawal(name, amount, currency, error) do
      case deposit(name, amount, currency) do
        {:ok, _amt} ->
          error;
        {:error, _e} ->
          revert_withdrawal(name, amount, currency, error)
      end
    end


  # @doc """
  #   Private function to call gen server cast methood
  #   When sender and receiver account is same get balance and return it as send operation complete.

  #   if failed to get balance then return appropriate error

  #   ## Parameters
  #     - :send - operation identifier
  #     - fromUser - amout sender
  #     - toUser - ammount reveiver
  #     - amount - transfer ammoun
  #     - currency - currency of the amount

  #   ## Output
  #     - {:ok, bal, bal} - balance of user
  #     - {:error, too_many_requests_to_user} - when operation queue has 10 queued
  #     - {:error, user_does_not_exist} - when user does not exist in system
  #     - {:error, not_enough_money} - when balance is less than transfer amount.
  # """
  defp cast({:send, fromUser, toUser, amount, currency}) when fromUser == toUser do
    case get_balance(fromUser, currency) do
      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_sender};
      {:error, :user_does_not_exist} ->
        {:error, :sender_does_not_exist};
      {:ok, amt} when amt < amount->
        {:error, :not_enough_money};
      {:ok, amt} ->
        {:ok, amt, amt}
    end

  end


  # @doc """
  #   Private function implemented send operation.
  #   Logic -
  #     1. Withdraw anount from from_user
  #       - If fails then return error
  #     2. Depost amount to to_user
  #       - If fails then revert withdrawal happened at step 1 (Keep retrying untill success)
  #       - reutn error for which deposti failed
  #     3. Return {:ok, balance_from_user, balance_to_user}

  #   ## Parameters
  #     - :send - operation identifier
  #     - fromUser - amout sender
  #     - toUser - ammount reveiver
  #     - amount - transfer ammoun
  #     - currency - currency of the amount

  #   ## Output
  #     - {:ok, bal, bal} - balance of user
  #     - {:error, too_many_requests_to_user} - when operation queue has 10 queued
  #     - {:error, user_does_not_exist} - when user does not exist in system
  #     - {:error, not_enough_money} - when balance is less than transfer amount.
  # """
  defp cast({:send, fromUser, toUser, amount, currency}) do
    case withdraw(fromUser, amount, currency) do
      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_sender};
      {:error, :user_does_not_exist} ->
        {:error, :sender_does_not_exist};
      {:error, :not_enough_money} ->
        {:error, :not_enough_money};
      {:ok, from_balance} ->
        case deposit(toUser, amount, currency) do
          {:error, :user_does_not_exist} ->
            revert_withdrawal(fromUser, amount, currency, {:error, :receiver_does_not_exist});
          {:error, :too_many_requests_to_user} ->
            revert_withdrawal(fromUser, amount, currency, {:error, :too_many_requests_to_receiver});
          {:ok, to_balance} ->
            {:ok, from_balance, to_balance}
        end
    end
  end


  # @doc """
  #   Private function to cast gen server function

  #   ## Parameters

  #   ## Output
  # """
  defp cast(msg) do
    ref = make_ref()
    pid = self()

    GenServer.cast(@name, {{pid, ref}, msg})

    receive do
      {^ref, reply} -> reply
    end
  end



  @doc """
    init - Gen server implemention

    ## Parameters

    ## Output
  """
  def init(args) do
    {:ok, args}
  end


  # @doc """
  #   handle_call - gen server implemention of handle call for create user.

  #   ## Parameters
  #     - name - name of user to create.

  #   ## Output
  #    - :ok - when create user successful
  #    - {:error, :user_already_exists} - when user already exist
  # """
  def handle_call({:create_user, name}, _from, state) do
    list = Enum.into state, %{}
    case list[name] do
      :nil ->
        {upid, _ref} = create_user_process(name)
        new_state = [{name, upid}|state]
        {:reply, :ok, new_state};
      _user_pid ->
        {:reply, {:error, :user_already_exists}, state}
    end
  end

  # @doc """
  #   handle_cast - gen server implemention of handle cast generic message
  #   Logic
  #     1. get user process id
  #       - failed to get user process, return error.
  #     2. pass message to uer process
  #       - user process will send appropriate response to caller pid

  #     ## Parameters
  #       - {pid, ref}=client, {name, msg} -
  #         pid - caller pid
  #         ref - call identifier
  #         name - user name
  #         msg - operation message

  #     ## Output
  #       Does not reuturn any value.
  # """
  def handle_cast({{pid, ref}=client, {name, msg}}, state) do
    list = Enum.into state, %{}
    case list[name] do
      :nil -> send(pid, {ref, {:error, :user_does_not_exist}});
      upid -> msg_to_user_process(upid, {client, msg})
    end
    {:noreply, state}
  end


  def handle_info({:DOWN, _ref, :process, pid, why}, state) do
    state1 = Enum.filter(
        state,
        fn({name, upid}) ->
          case (upid == pid) do
            true ->
              IO.puts "User process died #{name} reason #{why}"
              false
            _ -> true
          end
      end)
    {:noreply, state1}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # @doc """
  #   terminate - gen server default implemention
  # """
  def terminate(_reason, _state) do
    :ok
  end

  # @doc """
  #   code_change - gen server default implemention
  # """
  def code_change(_old_version, state, _extra) do
    {:ok, state}
  end



  # @doc """
  #   Private function to send msg to user process

  #   ##Parameters
  #     - upid - user process pid
  #     - {{pid, ref}=client, msg}
  #        * pid - Process id of caller
  #        * ref - message identifier
  #        * msg - operation message

  #   ## Output
  # """
  defp msg_to_user_process(upid, {{pid, ref}=client, msg}) do
    {_, mlist} = Process.info(upid, :messages)
    # todo move 10 to config

    case length(mlist) < 10 do
      :true -> send(upid, {client, msg})
      _ -> send(pid, {ref, {:error, :too_many_requests_to_user}});
    end
  end

  # @doc """
  #   Private function to spawn chlid process
  # """
  defp create_user_process(name) do
    spawn_monitor(fn -> ExUserProcess.init(name) end)
  end

end
