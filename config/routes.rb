Rails.application.routes.draw do

  root :to => "catalog#index"

  get '/admin_search', to: "admin_search#index"

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

  resources :languages do
    collection { get 'search' }
  end
  resources :manuscripts
  resources :places do
    collection { get 'search' }
  end
  resources :scribes do
    collection { get 'search' }
  end
  resources :sources do
    collection { get 'search' }
  end

  devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
