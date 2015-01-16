Rails.application.routes.draw do

  root :to => "catalog#index"

  get '/admin_search', to: "admin_search#index"
  post '/admin_search/calculate_bounds', to: "admin_search#calculate_bounds"

  resources :agents do
    collection { get 'search' }
  end
  resources :artists do
    collection { get 'search' }
  end
  resources :authors do
    collection { get 'search' }
  end

  blacklight_for :catalog

  get '/dashboard/', to: 'dashboard#show', as: 'dashboard'

  # handle these /entries/... URLs before EntriesController
  get '/entries/form_dropdown_values', to: 'entries#entry_form_dropdown_values'
  get '/entries/new', to: 'entries#new'
  get '/entries/:id.json', to: 'entries#show_json', defaults: { format: 'json' }
  get '/entries/:id', to: 'catalog#show', as: 'entry'
  resources :entries

  resources :entry_comments

  resources :languages do
    collection { get 'search' }
  end
  resources :manuscripts

  resources :places do
    collection { get 'search' }
  end

  get '/reports/', to: 'reports#show'
  get '/reports/artists/', to: 'reports#artists'
  get '/reports/authors/', to: 'reports#authors'

  resources :scribes do
    collection { get 'search' }
  end
  resources :sources do
    collection { get 'search' }
  end

  devise_for :users

end
