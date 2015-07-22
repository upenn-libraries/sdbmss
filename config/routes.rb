Rails.application.routes.draw do

  root :to => "catalog#index"

  resources :accounts, except: [:show] do
    collection do
      post 'mark_as_reviewed'
      get 'search'
    end
  end

  resources :agents, only: [:show]

  get '/bookmarks/export', to: 'bookmarks#export', as: 'export_bookmarks'

  # it would be cleaner to have :entries here and merge
  # CatalogController into EntriesController, but that doesn't work,
  # because Rails won't be able to find the catalog view files from
  # the blacklight gem.
  blacklight_for :catalog

  resources :comments do
    collection {
      post 'mark_as_reviewed'
      get 'search'
    }
  end

  get '/community/', to: 'community#show', as: 'community'
  get '/dashboard/', to: 'dashboard#show', as: 'dashboard'

  resources :delayed_jobs, only: [:index]

  # Note here that we point #show to BL's CatalogController
  resources :entries, except: [:show] do
    collection {
      post 'calculate_bounds'
      post 'mark_as_approved'
      get 'types'
    }
    member {
      get 'history'
      get 'similar'
      get 'manuscript_candidates'
    }
  end
  get '/entries/:id.json', to: 'entries#show_json', defaults: { format: 'json' }
  get '/entries/:id', to: 'catalog#show'

  resources :entry_comments

  resources :entry_dates do
    collection {
      get 'parse_observed_date'
    }
  end

  resources :entry_manuscripts do
    collection { put 'update_multiple' }
  end

  resources :events do
    collection {
      get 'parse_observed_date'
    }
  end

  get '/feedback/', to: 'feedback#index', as: 'feedback'
  post '/feedback/', to: 'feedback#send_email', as: 'send_feedback'
  get '/feedback/thanks', to: 'feedback#thanks', as: 'feedback_thanks'

  resources :languages do
    collection {
      post 'mark_as_reviewed'
      get 'search'
    }
  end

  get '/linkingtool/entry/:id', to: 'linking_tool#by_entry', as: 'linking_tool_by_entry'
  get '/linkingtool/manuscript/:id', to: 'linking_tool#by_manuscript', as: 'linking_tool_by_manuscript'

  # helpful for debugging
  get '/login_as/:username', to: 'accounts#login_as', as: 'login_as'

  resources :manuscripts do
    collection do
      post 'mark_as_reviewed'
      get 'search'
    end
    member do
      get 'citation'
      get 'entry_candidates'
      get 'manage_entries'
    end
  end

  resources :manuscript_comments

  resources :names do
    collection do
      post 'mark_as_reviewed'
      get 'search'
      get 'suggest'
    end
  end

  resources :places do
    collection {
      post 'mark_as_reviewed'
      get 'search'
    }
  end

  # use 'username' as identifier here for nicer URLs
  resources :profiles, only: [:show], param: :username

  if !Rails.env.production?
    get '/raise_error/', to: 'debug#raise_error'
  end

  get '/reports/', to: 'reports#show'
  get '/reports/names/', to: 'reports#names'
  get '/reports/languages/', to: 'reports#languages'
  get '/reports/places/', to: 'reports#places'
  get '/reports/sources/', to: 'reports#sources'

  resources :sources do
    collection do
      post 'mark_as_reviewed'
      get 'search'
      get 'similar'
      get 'types'
    end
    member do
      post 'update_status'
    end
  end

  devise_for :users, :controllers => { :registrations => "registrations" }

end
