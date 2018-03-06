Documentation::Engine.routes.draw do
  scope '/v/:version_ordinal', :constraints => { :version_ordinal => /[^\/]+/ } do
    match 'new(/*path)', :to => 'pages#new', :as => 'new_page', :via => [:get, :post]
    match 'positioning(/*path)', :to => 'pages#positioning', :as => 'page_positioning', :via => [:get, :post]
    match 'edit(/*path)', :to => 'pages#edit', :as => 'edit_page', :via => [:get, :patch]
    match 'delete(/*path)', :to => 'pages#destroy', :as => 'delete_page', :via => [:delete]
    match 'screenshot', :to => 'pages#screenshot', :as => 'upload_screenshot', :via => [:get, :post]
    get 'search', :to => 'pages#search', :as => 'search'
    get '*path' => 'pages#show', :as => 'page'
    root :to => 'pages#index'
  end
  match '/version_locales/new/:id', :to => 'version_locales#new', :as => 'new_version_locale', :via => [:get, :patch]
  match '/versions/new', :to => 'versions#new', :as => 'new_version', :via => [:get, :post]
  match '/versions/edit/:id', :to => 'versions#edit', :as => 'edit_version', :via => [:get, :patch]
  match '/versions/delete/:id', :to => 'versions#destroy', :as => 'delete_version', :via => [:delete]
  match '/versions', :to => 'versions#index', :as => 'versions', :via => [:get]
  match '/screenshots/delete/:id', :to => 'screenshots#destroy', :as => 'delete_screenshot', :via => [:delete]
  match '/screenshots', :to => 'screenshots#index', :as => 'screenshots', :via => [:get]
  get 'set_language/:locale', to: 'languages#set_language', as: 'set_language'
  root :to => 'pages#index', :as => 'unspecified_root'
end
