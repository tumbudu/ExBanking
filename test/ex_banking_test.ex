defmodule ExBankingTestTest do
	use ExUnit.Case, async: false
	doctest ExBanking

	test "Create user" do
		start_supervised!(ExBanking)
		assert :ok == ExBanking.create_user("test")
	end

	test "Create user" do
		start_supervised!(ExBanking)
		assert :ok == ExBanking.create_user("test")
	end

	test "Deposit" do
		start_supervised!(ExBanking)

		ExBanking.create_user("test")
		{:ok, existing_balance} = ExBanking.get_balance("test", "usd")
		ExBanking.deposit("test", 100, "usd")
		amount = existing_balance + 100
		assert {:ok amount} == ExBanking.get_balance("test" ,"usd")
	end

	test "Withdraw" do
		start_supervised!(ExBanking)
		ExBanking.create_user("test")

		{:ok, existing_balance} = ExBanking.get_balance("test", "usd")
		ExBanking.deposit("test", 100, "usd")
		ExBanking.withdraw("test", 100, "usd")
		assert {:ok existing_balance} == ExBanking.get_balance("test" ,"usd")
	end

	test "Get Balance" do
		start_supervised!(ExBanking)
		ExBanking.create_user("test1")
		ExBanking.deposit("test1", 100, "usd")
		assert {:ok 100} == ExBanking.get_balance("test1" ,"usd")
	end

	test "Send money" do
		start_supervised!(ExBanking)

		ExBanking.create_user("FromUser")
		ExBanking.deposit("FromUser", 100, "usd")

		ExBanking.create_user("ToUser")
		ExBanking.deposit("ToUser", 100, "usd")

		assert {:ok, 90, 110} = ExBanking.send("FromUser", "ToUser", 10, "usd")

	end


end
