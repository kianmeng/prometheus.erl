%% @doc
%% A registry of Collectors.
%%
%% The majority of users should use the `default', rather than their own.
%%
%% Creating a registry other than the default is primarily useful for
%% unit tests, or pushing a subset of metrics to the
%% <a href="https://github.com/prometheus/pushgateway">Pushgateway</a> from
%% batch jobs.
%% @end
-module(prometheus_registry).

-export([collect/2,
         collectors/1,
         register_collector/1,
         register_collector/2,
         register_collectors/1,
         register_collectors/2,
         deregister_collector/1,
         deregister_collector/2,
         clear/0,
         clear/1,
         collector_registeredp/1,
         collector_registeredp/2]).

-export_type([registry/0,
              collect_callback/0]).

-include("prometheus.hrl").

%%====================================================================
%% Types
%%====================================================================

-type registry() :: atom().

-type collect_callback() ::
        fun((registry(), prometheus_collector:collector()) -> any()).

%%====================================================================
%% Macros
%%====================================================================

-define(TABLE, ?PROMETHEUS_REGISTRY_TABLE).

%%====================================================================
%% Public API
%%====================================================================

-spec collect(Registry, Callback) -> ok when
    Registry :: prometheus_registry:registry(),
    Callback :: collect_callback().
collect(Registry, Callback) ->
  [Callback(Registry, Collector) ||
    {_, Collector} <- ets:lookup(?TABLE, Registry)],
  ok.

-spec collectors(Registry :: prometheus_registry:registry())
                -> [Collector :: prometheus_collector:collector()].
collectors(Registry) ->
  [Collector || {_, Collector} <- ets:lookup(?TABLE, Registry)].

-spec register_collector(Collector :: prometheus_collector:collector()) -> ok.
%% @equiv register_collector(default, Collector)
register_collector(Collector) ->
  register_collector(default, Collector).

-spec register_collector(Registry :: prometheus_registry:registry(),
                         Collector :: prometheus_collector:collector()) -> ok.
register_collector(Registry, Collector) ->
  ets:insert(?TABLE, {Registry, Collector}),
  ok.

-spec register_collectors(Collectors :: [prometheus_collector:collector()])
                         -> ok.
%% @equiv register_collectors(default, Collectors)
register_collectors(Collectors) ->
  register_collectors(default, Collectors).

-spec register_collectors(Registry :: prometheus_registry:registry(),
                          Collectors :: [prometheus_collector:collector()])
                         -> ok.
register_collectors(Registry, Collectors) ->
  [register_collector(Registry, Collector) || Collector <- Collectors],
  ok.

-spec deregister_collector(Collector :: prometheus_collector:collector()) -> ok.
%% @equiv deregister_collector(default, Collector)
deregister_collector(Collector) ->
  deregister_collector(default, Collector).

-spec deregister_collector(Registry :: prometheus_registry:registry(),
                           Collector :: prometheus_collector:collector()) -> ok.
deregister_collector(Registry, Collector) ->
  ets:delete_object(?TABLE, {Registry, Collector}),
  Collector:deregister_cleanup(Registry),
  ok.

%% @equiv clear(default)
-spec clear() -> ok.
clear() ->
  clear(default).

-spec clear(Registry :: prometheus_registry:registry()) -> ok.
clear(Registry) ->
  [Collector:deregister_cleanup(Registry) ||
    {_, Collector} <- ets:take(?TABLE, Registry)],
  ok.

-spec collector_registeredp(Collector) -> boolean() when
    Collector :: prometheus_collector:collector().
%% @equiv collector_registeredp(default, Collector)
collector_registeredp(Collector) ->
  collector_registeredp(default, Collector).

-spec collector_registeredp(Registry, Collector) -> boolean() when
    Registry  :: prometheus_registry:registry(),
    Collector :: prometheus_collector:collector().
collector_registeredp(Registry, Collector) ->
  case ets:match(?TABLE, {Registry, Collector}) of
    [] -> false;
    _  -> true
  end.
