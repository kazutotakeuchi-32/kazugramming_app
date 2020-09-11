Rails.application.routes.draw do
  get '/callback' => 'linebots#callback'
end
