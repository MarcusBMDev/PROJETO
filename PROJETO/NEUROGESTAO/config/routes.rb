Rails.application.routes.draw do
  # API Unified Routes - PRIORIDADE MÁXIMA
  namespace :api, defaults: { format: :json } do
    
    # 1. Rota da Dashboard corrigida (agora dentro do namespace API)
    get 'dashboard/stats', to: 'dashboard#stats'

    resources :data_pacientes, controller: 'data_pacientes' do
      patch 'reativar', on: :member
    end
    
    # Endpoint principal para compatibilidade no front
    get  'pacientes', to: 'data_pacientes#index'
    post 'pacientes', to: 'data_pacientes#create'
    put  'pacientes/:id', to: 'data_pacientes#update'
    patch 'pacientes/:id', to: 'data_pacientes#update'

    resources :profissionais do
      get 'especialidades', on: :collection
      post 'share_curriculo', on: :member
    end

    resources :convenios
    resources :lista_esperas, only: [:index, :create, :destroy]
    
    post 'importar_agenda', to: 'importacoes#upload_planilha'
    
    # 2. Rota de Transferências adicionada para o backend
    resources :transferencias do
      member do
        post :aprovar
        post :rejeitar
      end
    end
    
    resources :agendamentos do
      # Rotas de coleção (sem :id do resource)
      collection do
        get  :vagas
        get  :vagas_por_especialidade
        get  :sugerir
        post :transferir
        get  'por_profissional/:id', action: :por_profissional, as: :por_profissional
      end
      # Rotas de membro (com :id do resource)
      member do
        post :aprovar
      end
    end
  end

  # Página de entrada e navegação
  root to: 'application#renderizar_front_end'
  get '/dashboard', to: 'application#renderizar_dashboard'
  get '/grade',     to: 'application#renderizar_grade'
  get '/equipe',    to: 'application#renderizar_equipe'
  get '/espera',    to: 'application#renderizar_espera'
  get '/pacientes', to: 'application#renderizar_pacientes'
  get '/transferencias', to: 'application#renderizar_transferencias'
  get '/convenios_view', to: 'application#renderizar_convenios'
  
  post '/login', to: 'auth#login'
end