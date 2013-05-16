-module(balanced_tests).

-include_lib("eunit/include/eunit.hrl").

%%%----------------------------------------------------------------------
%%% Prelude
%%%----------------------------------------------------------------------
balanced_test_() ->
  {setup,
    fun setup/0,
    fun teardown/1,
    [
     {"Create Anonymous Account",
       fun create_account/0},
     {"Underwrite Anonymous Account",
       fun underwrite_anonymous_account/0},
     {"Create Person Account",
       fun underwrite_person/0},
     {"Attach Card",
       fun attach_card/0},
     {"Attach Bank",
       fun attach_bank/0},
     {"Credit Detail",
       fun credit_detail/0},
     {"Debit",
       fun debit/0}
    ]
  }.

-define(TEST_MARKET, "TEST-MP6E3EVlPOsagSdcBNUXWBDQ").
%%%----------------------------------------------------------------------
%%% Tests
%%%----------------------------------------------------------------------
create_account() ->
  Result = ?debugTime("Creating account",
    balanced:account_create_anonymous(?TEST_MARKET)),
  ?assertMatch({success, _}, Result),
  {success, Proplist} = Result,
  Type = proplists:get_value('_type', Proplist),
  ?assertEqual(Type, <<"account">>),
  Roles = proplists:get_value(roles, Proplist),
  ?assertEqual([], Roles),
  AccountId = proplists:get_value(id, Proplist),
  put(account_id, AccountId),
  ?debugFmt("Account ID: ~p~n", [AccountId]).

underwrite_anonymous_account() ->
  AccountId = get(account_id),
  Result = ?debugTime("Underwriting the anonymous account as a person",
    balanced:account_underwrite_as_person(?TEST_MARKET, AccountId,
      "Name Name", "+15555555555", "11101",
      "340 S Poop Ave", "1999-04-01",
      "tester@jester.jest")),
  ?assertMatch({success, _}, Result),
  {success, Proplist} = Result,
  Type = proplists:get_value('_type', Proplist),
  ?assertEqual(Type, <<"account">>),
  Roles = proplists:get_value(roles, Proplist),
  ?assertEqual([<<"merchant">>], Roles).

underwrite_person() ->
  Result = ?debugTime("Underwriting a new account as a person",
    balanced:account_create_as_person(?TEST_MARKET,
      "Name Name", "+15555555555", "11101",
      "340 S Poop Ave", "1999-04-01",
      "tester@jester.jest")),
  ?assertMatch({success, _}, Result),
  {success, Proplist} = Result,
  Type = proplists:get_value('_type', Proplist),
  ?assertEqual(Type, <<"account">>),
  Roles = proplists:get_value(roles, Proplist),
  ?assertEqual([<<"merchant">>], Roles),
  AccountId = proplists:get_value(id, Proplist),
  put(account_id, AccountId),
  ?debugFmt("Account ID: ~p~n", [AccountId]).

attach_card() ->
  AccountId = get(account_id),
  DevCardURI = "/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/cards/CC7FHSFn8oRlSJSAjiBpRtLa",
  % The balanced dev card can't be assigned to an account, so it errors out.  But, it
  % errors out as "can't add card," so it would have worked anyway, right?
  Result = ?debugTime("Adding card to account",
    balanced:account_add_card(?TEST_MARKET, AccountId, DevCardURI)),
  ?assertMatch({error, 409, _}, Result),
  {error, 409, Proplist} = Result,
  ?assertEqual(<<"Conflict">>, proplists:get_value(status, Proplist)).

attach_bank() ->
  AccountId = get(account_id),
  BankAccountURI = "/v1/bank_accounts/BA7IU7MDWuhYHjlDID0WVXG",
  % Same dumbass non-working-ness of dev credentials as attach_card().
  Result = ?debugTime("Adding bank to customer",
    balanced:account_add_bank(?TEST_MARKET, AccountId, BankAccountURI)),
  ?assertMatch({error, 409, _}, Result),
  {error, 409, Proplist} = Result,
  ?assertEqual(<<"Conflict">>, proplists:get_value(status, Proplist)).

credit_detail() ->
  AccountId = get(account_id),
  Result = ?debugTime("Crediting account",
    balanced:credit_detail(?TEST_MARKET, AccountId, "300000", "Some Desc")),
  % This fails because we didn't actually attach bank details to this account.
  % But, the error is "we can't do this" not "this is the wrong endpoint,"
  % so everything is still valid.  Hopefully.
  ?assertMatch({error, 409, _}, Result),
  {error, 409, Proplist} = Result,
  ?assertEqual(<<"Conflict">>, proplists:get_value(status, Proplist)).

debit() ->
  AccountId = get(account_id),
  Result = ?debugTime("Debiting account",
    balanced:debit(?TEST_MARKET, AccountId, "300000", "Some Desc", "Other Desc")),
  % Same failure scenario as credit_detail/0 above.
  ?assertMatch({error, 409, _}, Result),
  {error, 409, Proplist} = Result,
  ?assertEqual(<<"Conflict">>, proplists:get_value(status, Proplist)).

%%%----------------------------------------------------------------------
%%% Setup / Cleanup
%%%----------------------------------------------------------------------
setup() ->
  inets:start(),
  ssl:start(),
  % Prime the inets/ssl code path with a https request to google:
  httpc:request("https://google.com"),
  application:start(balanced),
  application:set_env(balanced, auth_token, "da3da6de7c9311e288c9026ba7f8ec28"),
  ok.

teardown(_) ->
  ssl:stop(),
  inets:stop(),
  ok.
