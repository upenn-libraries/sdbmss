Rails.application.routes.draw do

  root :to => "catalog#index"

  get '/admin_search', to: "admin_search#index"
  post '/admin_search/calculate_bounds', to: "admin_search#calculate_bounds"

  resources :agents, only: [:show]

  # it would be cleaner to have :entries here and merge
  # CatalogController into EntriesController, but that doesn't work,
  # because Rails won't be able to find the catalog view files from
  # the blacklight gem.
  blacklight_for :catalog

  get '/dashboard/', to: 'dashboard#show', as: 'dashboard'

  # TODO: this is gross, but we want some /entries[...] URLs to be
  # handled by CatalogController and some by EntriesController and it
  # is difficult to tweak the 'resources' DSL to get the exact desired
  # behavior.

  get '/entries/types', to: 'entries#types'
  get '/entries/new', to: 'entries#new'
  get '/entries/:id/history', to: 'entries#history', as: 'entry_history'
  get '/entries/:id/similar', to: 'entries#similar'
  get '/entries/:id/manuscript_candidates', to: 'entries#manuscript_candidates'
  get '/entries/:id.json', to: 'entries#show_json', defaults: { format: 'json' }
  get '/entries/:id', to: 'catalog#show', as: 'entry'
  resources :entries

  resources :entry_comments

  resources :entry_manuscripts do
    collection { put 'update_multiple' }
  end

  resources :languages do
    collection { get 'search' }
  end

  get '/linkingtool/entry/:id', to: 'linking_tool#by_entry', as: 'linking_tool_by_entry'
  get '/linkingtool/manuscript/:id', to: 'linking_tool#by_manuscript', as: 'linking_tool_by_manuscript'

  resources :manuscripts do
    collection { get 'search' }
    member do
      get 'entry_candidates'
      get 'manage_entries'
    end
  end

  resources :manuscript_comments

  resources :names do
    collection do
      get 'search'
      get 'suggest'
    end
  end

  resources :places do
    collection { get 'search' }
  end

  get '/profiles/:username', to: 'profiles#show', as: 'profile'

  get '/reports/', to: 'reports#show'
  get '/reports/names/', to: 'reports#names'
  get '/reports/languages/', to: 'reports#languages'
  get '/reports/places/', to: 'reports#places'
  get '/reports/sources/', to: 'reports#sources'

  resources :sources do
    collection do
      get 'search'
      get 'types'
    end
    member do
      post 'update_status'
    end
  end

  devise_for :users

end
