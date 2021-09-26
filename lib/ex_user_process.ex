defmodule ExUserProcess do

  	@decimals 2

	import ExUser

	@doc """
		init child process and start listen_loop with initial state.
	"""
	def init(name) do
		me = %ExUser{name: name, list_balance: []}
		listen_loop(me)
	end

	# @doc """
	# 	listen_loop of user process

	# 	User process to maintain balance and process operations

	# 	- get_balance
	# 		Get balance and send to caller pid with ref
	# 	- deposit
	# 		Update balance and send updated balance to caller pid with ref
	# 	- withdraw
	# 		Update balance and send updated balance to caller pid with ref
	# """
	defp listen_loop(me) do
		receive do

			{{pid, ref}, {:get_balance, currency}} ->
				balance_list = me.list_balance
				balance = get_balance(balance_list, currency)
				send pid, {ref, {:ok, balance}}
				listen_loop(me);

			{{pid, ref}, {:deposit, amount, currency}} ->
				balance_list = me.list_balance
				balance = get_balance(balance_list, currency)
				finalbal = round_balance(balance + amount)

				send pid, {ref, {:ok, finalbal}}

				updated_balance_list = add_balance(balance_list, amount, currency)
				listen_loop(%{me|list_balance: updated_balance_list});

			{{pid, ref}, {:withdraw, amount, currency}} ->
				balance_list = me.list_balance
				balance = get_balance(balance_list, currency)

				case balance >= amount do
					:false ->
						send pid, {ref, {:error, :not_enough_money}}
						listen_loop(me);
					_ ->
						finalbal = balance - amount
						send pid, {ref, {:ok, round_balance(finalbal)}}
						updated_balance_list = deduct_balance(balance_list, amount, currency)
						listen_loop(%{me|list_balance: updated_balance_list})
				end
		end
	end


	defp get_balance(list, currency) do
		atom_currency = String.to_atom(currency)
		mlist = Enum.into list, %{}
		case mlist[atom_currency] do
			:nil -> 0.00;
			amt -> amt
		end
	end

	defp add_balance(list, amount, currency) do
		atom_currency = String.to_atom(currency)
		case Keyword.get(list, atom_currency) do
			:nil ->
				[{atom_currency, amount}|list];
			previous_amount ->
				Keyword.put(list, atom_currency, round_balance(previous_amount + amount))
		end
	end

	defp deduct_balance(list, amount, currency) do
		atom_currency = String.to_atom(currency)
		previous_amount = Keyword.get(list, atom_currency)
		Keyword.put(list, atom_currency, round_balance(previous_amount - amount))
	end

	defp round_balance(amt) when is_float(amt) do
		Float.round(amt, @decimals)
	end

	defp round_balance(amt) when is_integer(amt) do
		Float.round(amt * 1.0, @decimals)
	end

end

