Rails.application.routes.draw do

  mount Thredded::Engine => '/forum'
  
  root :to => "catalog#index"

  resources :accounts, except: [:show] do
    collection do
      post 'add_to_group'
      post 'remove_from_group'
      post 'mark_as_reviewed'
      get 'search'
    end
  end

  resources :activities do
    collection {
      get 'index'
      get 'show_all'
    }
  end

  resources :pages, param: :name do
    member {
      post 'preview'
    }
  end

  resources :watches, only: [:index, :create, :destroy]
  resources :ratings, only: [:create, :destroy, :update]

  resources :groups do
    collection {
      get 'show_all'
    }
  end
  resources :group_users
  
  resources :dericci_records
  resources :dericci_games
  resources :dericci_links

  resources :replies
  resources :notifications, only: [:index, :show, :update, :destroy]
  #resources :notifications_settings, only: [:edit]

  #resources :agents, only: [:show]

  get '/bookmarks/export', to: 'bookmarks#export', as: 'export_bookmarks'
  get '/bookmarks/reload', to: 'bookmarks#reload', as: 'reload_bookmarks'
  resources :bookmarks do
    collection {
      delete 'delete_all'
      get 'check'
    }
    member {
      get 'addtag'
      get 'removetag'
    }
  end

  resources :downloads do
    collection {
      get 'index', as: "downloads"
    }
    member {
      get 'show' 
      get 'delete', action: :destroy
    }
  end

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

  get "/faq/", to: 'community#faq', as: 'faq'
  get "/about/", to: 'community#about', as: 'about'
  get "/technical_overview/", to: 'community#technical_overview', as: 'technical_overview'
  get "/project_history/", to: 'community#project_history', as: 'project_history'
  get "/user_agreement/", to: 'community#user_agreement', as: 'user_agreement'
  get '/community/', to: 'community#show', as: 'community'
  get '/dashboard/', to: 'dashboard#contributions'
  get '/dashboard/contributions'
  get '/dashboard/activity'
  get '/dashboard/forum'

#  resources :delayed_jobs, only: [:index]

#  resources '/messages/', to: 'private_messages#index', as: 'private_messages'

  resources :private_messages do
  end

  # Note here that we point #show to BL's CatalogController
  resources :entries, except: [:show] do
    collection {
      post 'calculate_bounds'
      post 'mark_as_approved'
      post 'add_to_group'
      post 'remove_from_group'
      get 'types'
    }
    member {
      patch '/revert_confirm/', to: 'entries#revert_confirm'
      patch '/revert/', to: 'entries#revert'
      post 'deprecate'
      post 'compose'
      get 'verify'
      get 'history'
      get 'similar'
      get 'manuscript_candidates'
    }
  end
  get '/entries/:id.json', to: 'entries#show_json', defaults: { format: 'json' }
  get '/entries/:id', to: 'catalog#show'
  get '/feed' => 'entries#feed'

  resources :entry_dates do
    collection {
      get 'parse_observed_date'
    }
  end

  resources :entry_manuscripts do
    collection {
      post 'mark_as_reviewed'
      get 'search'
      put 'update_multiple'
    }
  end

  get '/feedback/', to: 'feedback#index', as: 'feedback'
  post '/feedback/', to: 'feedback#send_email', as: 'send_feedback'
  get '/feedback/thanks', to: 'feedback#thanks', as: 'feedback_thanks'

  resources :languages do
    collection {
      post 'mark_as_reviewed'
      get 'search'
      get 'more_like_this'
    }
    member do
      get 'history'
      patch '/revert_confirm/', to: 'languages#revert_confirm'
      patch '/revert/', to: 'languages#revert'
    end
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
      get 'history'
      get 'edit', action: :show
    end
  end

  resources :names do
    collection do
      post 'mark_as_reviewed'
      get 'search'
      get 'suggest'
      get 'more_like_this'
    end
    member do
      patch '/revert_confirm/', to: 'names#revert_confirm'
      patch '/revert/', to: 'names#revert'
      get 'history'
      get 'merge'
      post 'merge'
    end
  end

  resources :places do
    collection {
      post 'mark_as_reviewed'
      get 'search'
      get 'more_like_this'
    }
    member do
      get 'history'
      patch '/revert_confirm/', to: 'places#revert_confirm'
      patch '/revert/', to: 'places#revert'
    end
  end

  # use 'username' as identifier here for nicer URLs
  resources :profiles, only: [:show], param: :username

  resources :provenance do
    collection {
      get 'parse_observed_date'
    }
  end

  if !Rails.env.production?
    get '/raise_error/', to: 'debug#raise_error'
  end

  resources :sources do
    collection do
      post 'calculate_bounds'
      post 'mark_as_reviewed'
      get 'search'
      get 'similar'
      get 'conflict'
      get 'types'
    end
    member do
      get 'merge'
      post 'merge'
      get 'history'
      post 'update_status'
    end
  end

  devise_for :users, :controllers => { :registrations => "registrations" }

end
