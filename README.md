balanced-erlang: balancedpayments client.  erlang flavored.
===========================================================

Status
------
balanced-erlang is a minimal balancedpayments client.

It currently only supports operations required to pay and get paid.  Anything
else you need can be handled from the balancedpayments console for now.

The operations we have so far: creating a new anonymous account, creating
a new account as a person/merchant so they can receive payments,
attaching a credit card to an account, attaching a bank account to an account,
debiting a credit card, and crediting a bank account.

Usage
-----
### Overview
    matt@nibonium:~/repos/balanced-erlang% erl -pa ebin deps/*/ebin
    Erlang R16B (erts-5.10.1) [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Eshell V5.10.1  (abort with ^G)
    1> inets:start().
    ok
    2> ssl:start().
    ok
    3> application:start(balanced).
    ok
    4> application:set_env(balanced, auth_token, "da3da6de7c9311e288c9026ba7f8ec28").
    ok
    5> TestMarketId = "TEST-MP6E3EVlPOsagSdcBNUXWBDQ".
    "TEST-MP6E3EVlPOsagSdcBNUXWBDQ"
    6> balanced:account_create_anonymous(TestMarketId).
    {success,[{'_type',<<"account">>},
              {'_uris',[{holds_uri,[{'_type',<<"page">>},
                                    {key,<<"holds">>}]},
                        {bank_accounts_uri,[{'_type',<<"page">>},
                                            {key,<<"bank_accounts">>}]},
                        {refunds_uri,[{'_type',<<"page">>},{key,<<"refunds">>}]},
                        {customer_uri,[{'_type',<<"customer">>},
                                       {key,<<"customer">>}]},
                        {debits_uri,[{'_type',<<"page">>},{key,<<"debits">>}]},
                        {transactions_uri,[{'_type',<<"page">>},
                                           {key,<<"transactions">>}]},
                        {credits_uri,[{'_type',<<"page">>},{key,<<"credits">>}]},
                        {cards_uri,[{'_type',<<"page">>},{key,<<"cards">>}]}]},
              {bank_accounts_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC1JATXa5jXeFRUKvC26Oobc/bank_ac"...>>},
              {meta,[]},
              {transactions_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC1JATXa5jXeFRUKvC26Oobc"...>>},
              {email_address,null},
              {id,<<"AC1JATXa5jXeFRUKvC26Oobc">>},
              {credits_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC1JATXa5jXe"...>>},
          {cards_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC1JATXa"...>>},
          {holds_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC1J"...>>},
          {name,null},
          {roles,[]},
          {created_at,<<"2013-05-14T16:27:51.640303Z">>},
          {uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWB"...>>},
          {refunds_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBN"...>>},
          {customer_uri,<<"/v1/customers/AC1JATXa5jXeFRUKvC26Oo"...>>},
          {debits_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPO"...>>}]}
    7> balanced:account_create_as_person(TestMarketId, "My Name", "+15551234567", "11101", "320 Pioneer Way", "1983-06-21", "email@noteven.com").
    {success,[{'_type',<<"account">>},
              {'_uris',[{holds_uri,[{'_type',<<"page">>},
                                    {key,<<"holds">>}]},
                        {bank_accounts_uri,[{'_type',<<"page">>},
                                            {key,<<"bank_accounts">>}]},
                        {refunds_uri,[{'_type',<<"page">>},{key,<<"refunds">>}]},
                        {customer_uri,[{'_type',<<"customer">>},
                                       {key,<<"customer">>}]},
                        {debits_uri,[{'_type',<<"page">>},{key,<<"debits">>}]},
                        {transactions_uri,[{'_type',<<"page">>},
                                           {key,<<"transactions">>}]},
                        {credits_uri,[{'_type',<<"page">>},{key,<<"credits">>}]},
                        {cards_uri,[{'_type',<<"page">>},{key,<<"cards">>}]}]},
              {bank_accounts_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC3YLJzg64VolwjSIXBO9YsG/bank_ac"...>>},
              {meta,[]},
              {transactions_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC3YLJzg64VolwjSIXBO9YsG"...>>},
              {email_address,null},
              {id,<<"AC3YLJzg64VolwjSIXBO9YsG">>},
              {credits_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC3YLJzg64Vo"...>>},
              {cards_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC3YLJzg"...>>},
              {holds_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/accounts/AC3Y"...>>},
              {name,<<"My Name">>},
              {roles,[<<"merchant">>]},
              {created_at,<<"2013-05-14T16:29:55.377273Z">>},
          {uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWB"...>>},
          {refunds_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBN"...>>},
          {customer_uri,<<"/v1/customers/AC3YLJzg64VolwjSIXBO9Y"...>>},
          {debits_uri,<<"/v1/marketplaces/TEST-MP6E3EVlPO"...>>}]}
    8> CreatedAccountId = "AC3YLJzg64VolwjSIXBO9YsG".
    "AC3YLJzg64VolwjSIXBO9YsG"
    9> PublicDevCardURI = "/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/cards/CC7FHSFn8oRlSJSAjiBpRtLa".
    "/v1/marketplaces/TEST-MP6E3EVlPOsagSdcBNUXWBDQ/cards/CC7FHSFn8oRlSJSAjiBpRtLa"
    10> balanced:account_add_card(TestMarketId, CreatedAccountId, PublicDevCardURI).
    {error,409,
           [{status,<<"Conflict">>},
            {category_code,<<"card-already-funding-src">>},
            {additional,null},
            {status_code,409},
            {category_type,<<"logical">>},
            {extras,[]},
            {request_id,<<"OHMb2450608bcb311e2848c026ba7cac9da">>},
            {description,<<"Card has already been associated with an account. Your request i"...>>}]}
    11> PublicDevBankURI = "/v1/bank_accounts/BA7IU7MDWuhYHjlDID0WVXG".
    "/v1/bank_accounts/BA7IU7MDWuhYHjlDID0WVXG"
    12> balanced:account_add_bank(TestMarketId, CreatedAccountId, PublicDevBankURI).
    {error,409,
           [{status,<<"Conflict">>},
            {category_code,<<"bank-account-already-associated">>},
            {additional,null},
            {status_code,409},
            {category_type,<<"logical">>},
            {extras,[]},
            {request_id,<<"OHMc36d5408bcb311e2a260026ba7c1aba6">>},
            {description,<<"Bank account has already been associated with an account. Your r"...>>}]}
    13> balanced:credit_detail(TestMarketId, CreatedAccountId, "300000", "Test Transaction").
    {error,409,
           [{status,<<"Conflict">>},
            {category_code,<<"no-funding-destination">>},
            {additional,null},
            {status_code,409},
            {category_type,<<"logical">>},
            {extras,[]},
            {request_id,<<"OHMddc8920ebcb311e2a6a6026ba7cac9da">>},
            {description,<<"Account AC3YLJzg64VolwjSIXBO9YsG has no funding destination. You"...>>}]}
    14> balanced:debit(TestMarketId, CreatedAccountId, "65000000", "Test Debit", "Debit Note Internal").
    {error,409,
           [{status,<<"Conflict">>},
            {category_code,<<"no-funding-source">>},
            {additional,null},
            {status_code,409},
            {category_type,<<"logical">>},
            {extras,[]},
            {request_id,<<"OHMf7fca1ecbcb311e2ae3f026ba7c1aba6">>},
            {description,<<"Account AC3YLJzg64VolwjSIXBO9YsG has no funding source. Your req"...>>}]}


Note: The last few errors above are normal.  The balanced dev tokens/keys/URIs don't work properly for
actual testing.  Annoying.

### Configuration
You must start `inets` and `ssl` before using `balanced`.

By default, erlang-balanced uses the global balanced API test token.
You *must* change this to your private API key before you can receive payments:

    inets:start(),
    ssl:start(),
    application:start(balanced),
    application:set_env(balanced, auth_token, "da3da6de7c9311e288c9026ba7f8ec28").

Building
--------
        rebar get-deps
        rebar compile

Testing
-------
        rebar eunit skip_deps=true suite=balanced

Next Steps
----------
In no specific order:

* Flesh out remaining balanced API
* Add tests for error conditions
* Move from env-specified auth token to something more call specific
  * Options:
    * Per-call auth token (balanced:charge_card(AuthToken, ...))
    * Leave env, but add per-auth token options

Contributions
-------------
Want to help?  Patches welcome.

* Find a bug.  Fix a bug.
