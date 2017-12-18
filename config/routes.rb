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
  match '/versions/new', :to => 'versions#new', :as => 'new_version', :via => [:get, :post]
  match '/versions/edit/:id', :to => 'versions#edit', :as => 'edit_version', :via => [:get, :patch]
  match '/versions/delete/:id', :to => 'versions#destroy', :as => 'delete_version', :via => [:delete]
  match '/versions', :to => 'versions#index', :as => 'versions', :via => [:get]
  root :to => 'pages#index', :as => 'unspecified_root'
end
