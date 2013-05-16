-module(balanced).

-export([account_create_anonymous/1, account_create_as_person/7]).
-export([account_underwrite_as_person/8]).
-export([account_add_card/3, account_add_bank/3]).
-export([credit_from_uri/3, credit_detail/4]).
-export([debit/5]).

-define(VSN_BIN, <<"0.3">>).
-define(VSN_STR, binary_to_list(?VSN_BIN)).

%%%--------------------------------------------------------------------
%%% Account Creation
%%%--------------------------------------------------------------------
account_create_anonymous(MarketId) ->
  request_account_create(MarketId).

account_create_as_person(MarketId,
                         Name, Phone, Postal, StreetAddress, DOB, Email) ->
  Fields = [{"merchant[type]", "person"},
            {"merchant[name]", Name},
            {"merchant[phone_number]", Phone},
            {"merchant[postal_code]", Postal},
            {"merchant[street_address]", StreetAddress},
            {"merchant[dob]", DOB},
            {"merchant[email_address]", Email}],

  OnlyWithValues = [{K, V} || {K, V} <- Fields, V =/= [] andalso V =/= <<>>],
  request_account_underwrite(MarketId, OnlyWithValues).

account_underwrite_as_person(MarketId, AccountId,
                         Name, Phone, Postal, StreetAddress, DOB, Email) ->
  Fields = [{"merchant[type]", "person"},
            {"merchant[name]", Name},
            {"merchant[phone_number]", Phone},
            {"merchant[postal_code]", Postal},
            {"merchant[street_address]", StreetAddress},
            {"merchant[dob]", DOB},
            {"merchant[email_address]", Email}],

  OnlyWithValues = [{K, V} || {K, V} <- Fields, V =/= [] andalso V =/= <<>>],
  request_account_underwrite(MarketId, AccountId, OnlyWithValues).

%%%--------------------------------------------------------------------
%%% Account Manipulation
%%%--------------------------------------------------------------------
account_add_card(MarketId, AccountId, CardURI) ->
  request_account_add_thing(MarketId, AccountId, {card_uri, CardURI}).

account_add_bank(MarketId, AccountId, BankURI) ->
  request_account_add_thing(MarketId, AccountId, {bank_account_uri, BankURI}).

%%%--------------------------------------------------------------------
%%% Payout to Bank
%%%--------------------------------------------------------------------
credit_from_uri(CreditURI, Amount, Desc) ->
  Fields = [{"amount", l(Amount)},
            {"desc", Desc}],

  OnlyWithValues = [{K, V} || {K, V} <- Fields, V =/= [] andalso V =/= <<>>],
  request_credit(CreditURI, OnlyWithValues).

credit_detail(MarketId, AccountId, Amount, StatementDesc) ->
  Fields = [{"amount", l(Amount)},
            {"appears_on_statement_as", StatementDesc}],

  OnlyWithValues = [{K, V} || {K, V} <- Fields, V =/= [] andalso V =/= <<>>],
  request_credit_detail(MarketId, AccountId, OnlyWithValues).

%%%--------------------------------------------------------------------
%%% Pay from Credit Card
%%%--------------------------------------------------------------------
debit(MarketId, AccountId, Amount, StatementDesc, LocalDesc) ->
  Fields = [{"amount", l(Amount)},
            {"appears_on_statement_as", StatementDesc},
            {"description", LocalDesc}],

  OnlyWithValues = [{K, V} || {K, V} <- Fields, V =/= [] andalso V =/= <<>>],
  request_debit(MarketId, AccountId, OnlyWithValues).

%%%--------------------------------------------------------------------
%%% request generation and sending
%%%--------------------------------------------------------------------
request_account_create(MarketId) ->
  request_run(gen_action_url(MarketId, accounts), post, []).

request_account_add_thing(MarketId, AccountId, ThingToAdd) ->
 request_run(gen_account_url(MarketId, AccountId), put, [ThingToAdd]).

request_account_underwrite(MarketId, Fields) ->
  request_run(gen_action_url(MarketId, accounts), post, Fields).

request_account_underwrite(MarketId, AccountId, Fields) ->
  request_run(gen_account_url(MarketId, AccountId), put, Fields).

request_credit(CreditURI, Fields) ->
  request_run(gen_gen_url(CreditURI), post, Fields).

request_credit_detail(MarketId, AccountId, Fields) ->
  request_run(gen_credits_url(MarketId, AccountId), post, Fields).

request_debit(MarketId, AccountId, Fields) ->
  request_run(gen_debits_url(MarketId, AccountId), post, Fields).

request_run(URL, Method, Fields) ->
  Headers = [{"X-Balanced-Client-User-Agent", ua_json()},
             {"User-Agent", "balanced/v1 ErlangBindings/" ++ ?VSN_STR},
             {"Authorization", auth_key()}],
  Type = "application/x-www-form-urlencoded",
  Body = gen_args(Fields),
  Request = case Method of
              % get and delete are body-less http requests
                 get -> {URL, Headers};
              delete -> {URL, Headers};
                   _ -> {URL, Headers, Type, Body}
            end,
%  io:format("requesting... ~p; ~p, ~p, ~p~n", [Method, URL, Fields, Body]),
  Requested = httpc:request(Method, Request, [], []),
  resolve(Requested).

%%%--------------------------------------------------------------------
%%% response parsing
%%%--------------------------------------------------------------------
resolve({ok, {{_HTTPVer, StatusCode, _Reason}, _Headers, Body}}) ->
  resolve_status(StatusCode, Body);
resolve({ok, {StatusCode, Body}}) ->
  resolve_status(StatusCode, Body);
resolve({error, Reason}) ->
  {error, Reason}.

resolve_status(HTTPStatus, SuccessBody) when
    HTTPStatus >= 200 andalso HTTPStatus < 300 ->
  {success, flat_decode(SuccessBody)};
resolve_status(HTTPStatus, ErrorBody) ->
  {error, HTTPStatus, flat_decode(ErrorBody)}.


flat_decode(StringJson) ->
  Proplist = mochijson2:decode(StringJson, [{format, proplist}]),
  % I like me some atoms.  We have limited return keys from the API
  % so this should be reasonably safe.
  atomize(Proplist).

atomize(P) -> atomize(P, []).

atomize([{K, V} | T], Accum) when is_list(V) ->
  % the API returns nested json structures, so we convert those
  % keys to atoms too.  no atom left behind.
  atomize(T, [{binary_to_atom(K, utf8), atomize(V)} | Accum]);
atomize([{K, V} | T], Accum) ->
  atomize(T, [{binary_to_atom(K, utf8), V} | Accum]);
atomize([H | T], Accum) ->
  atomize(T, [H | Accum]);
atomize([], Accum) ->
  lists:reverse(Accum).

%%%--------------------------------------------------------------------
%%% value helpers
%%%--------------------------------------------------------------------
ua_json() ->
  Props = [{<<"bindings_version">>, ?VSN_BIN},
           {<<"lang">>, <<"erlang">>},
           {<<"publisher">>, <<"mattsta">>}],
  binary_to_list(iolist_to_binary(mochijson2:encode(Props))).

auth_key() ->
  Token = env(auth_token),
  Auth = base64:encode_to_string(Token ++ ":"),
  "Basic " ++ Auth.

env(What) ->
  case env(What, diediedie) of
    diediedie -> throw({<<"You must define this in your app:">>, What});
         Else -> Else
  end.

env(What, Default) ->
  case application:get_env(balanced, What) of
    {ok, Found} -> Found;
      undefined -> Default
  end.

gen_args([]) -> "";
gen_args(Fields) when is_list(Fields) andalso is_tuple(hd(Fields)) ->
  mochiweb_util:urlencode(Fields).

% Balanced API has a dumb limit where it breaks if you have double slashes,
% so something like http://apifoo//hello///here breaks badly.  Only one
% slash allowed between things.  Makes you wonder what they are using
% to tokenize the URIs, doesn't it?
gen_gen_url(URI) ->
  UseURI = l(URI),
  case hd(UseURI) of
    $/ -> ok;
     _ -> throw({uri_must_start_with_slash, UseURI})
   end,
  "https://api.balancedpayments.com" ++ UseURI.

gen_market_url(MarketId) ->
  "https://api.balancedpayments.com/v1/marketplaces/" ++ l(MarketId).

gen_action_url(MarketId, Action) ->
  gen_market_url(MarketId) ++ "/" ++ l(Action).

gen_account_url(MarketId, AccountId) ->
  gen_action_url(MarketId, accounts) ++ "/" ++ l(AccountId).

gen_credits_url(MarketId, AccountId) ->
  gen_account_url(MarketId, AccountId) ++ "/credits".

gen_debits_url(MarketId, AccountId) ->
  gen_account_url(MarketId, AccountId) ++ "/debits".

%%%--------------------------------------------------------------------
%%% Formatters
%%%--------------------------------------------------------------------
l(L) when is_list(L) -> L;
l(B) when is_binary(B) -> binary_to_list(B);
l(I) when is_integer(I) -> integer_to_list(I);
l(A) when is_atom(A) -> atom_to_list(A).
