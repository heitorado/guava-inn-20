[![Maintainability](https://api.codeclimate.com/v1/badges/9f693e764e1e84c6ca23/maintainability)](https://codeclimate.com/github/heitorado/guava-inn-20/maintainability)
[![codecov](https://codecov.io/gh/heitorado/guava-inn-20/branch/trunk/graph/badge.svg)](https://codecov.io/gh/heitorado/guava-inn-20)
[![Guava Inn](https://circleci.com/gh/heitorado/guava-inn-20.svg?style=shield)](https://app.circleci.com/pipelines/github/heitorado/guava-inn-20)
[![time tracker](https://wakatime.com/badge/github/heitorado/guava-inn-20.svg)](https://wakatime.com/badge/github/heitorado/guava-inn-20)

# Aos avaliadores

Olá! Aqui está a entrega do meu projeto para o processo seletivo da Guava.
Além de todo o código nesse repositório, também configurei e utilizei algumas ferramentas externas para auxiliar o desenvolvimento e/ou automatizar processos e checar qualidade.

- Logo acima é possível acessar, clicando nas badges:
    - A página do repositório no CodeClimate e Codecov, para verificação de mantenabilidade do código e cobertura dos testes.
    - Pipelines de build, test e deploy no CircleCI configuradas para o projeto
    - Tempo gasto no desenvolvimento registrado através do Wakatime.
- Para organização das tarefas, foi utilizado o sistema de issues do github administrado pela plataforma Zenhub, que pode ser [acessado aqui](https://app.zenhub.com/workspaces/guava-inn-5f0e4270ba4feb0016b27f90/board), mas também é possível ver tudo na aba de 'Issues' do projeto (filtrando pelas issues fechadas).
- Para cada issue criada, procurei fechá-la incluindo no commit que implementava/resolvia o que era proposto a mensagem "Closes #X".
- Geralmente eu prefiro manter somente o branch principal (no caso deste projeto, o trunk) no repositório. Mas como não sei se os branches ajudariam na avaliação do processo de desenvolvimento, deixei todos eles remotos.
- O Deploy do projeto foi feito com a gem Capistrano em um servidor do Digital Ocean, e pode ser acessado através do link [guava-inn.tech](https://guava-inn.tech/).
- O README original foi renomeado para `GUAVA_PROJECT_SPECS.md`.

# Diário de Desenvolvimento
14/07
- Setup inicial
- Rodei todos os testes
- Corrigi um dos testes que estava quebrando
- Estudei capybara, revisei rspec e pesquisei sobre boas práticas na escrita de testes, pois não tenho familiaridade com a prática

15/07
- Busca corrigida e devidamente implementada para listar quartos disponíveis
- A mensagem de aviso que deve ser mostrada quando busca não retorna resultados já estava presente na aplicação, então enviei email para sanar a dúvida se deveria ser modificado ou não.
- Iniciei a criação de testes para validação de reservas e outros

16/07
- Finalizei a criação de testes e implementação de validações, merge no branch principal
- Fiz a Refatoração de teste já existente (só rename variable basicamente)
- Passei a tarde toda escrevendo testes para taxa de ocupação, e refinando a função conforme testes quebravam. Demorei para entender a sacada do "meio dia", mas após entender e descobrir o que causava o resultado em alguns casos (faltar sempre 1 dia na conta do mês) os testes fluíram melhor e o código do método também.
- Pausa para ideias no fim do dia de como seria a melhor forma de exibir esses cálculos na view
  - A ideia de a cada refresh recalcular o valor parece ruim. cogitei guardar no model `Room` os valores de taxa de ocupação mensal e semanal, sempre que uma nova reserva fosse criada, contendo nela os dias sendo observados (7 e 30 dias a partir de hoje).
    - O problema com isso é que todo dia as 0:00 a taxa precisaria ser recalculada. Poderia ser feito utilizando cronjobs com a gem `whenever` que acionaria uma `rake task` para atualizar todos os models, colocando os cálculos a serem feitos em uma fila de processamento em segundo plano com ActiveJob podendo usar `sidekiq` ou `delayedjob` em produção.
  - Ainda que isso fosse feito, seria necessário iterar sempre por todos os quartos e calcular a média toda vez.
    - Para contornar isso, poderia-se criar um model para armazenar as estatísticas e guardá-las diariamente, claro, também atualizando esse model todo dia com serviços periódicos.
    - Além de resolver o problema de escalabilidade e possivel sobrecarga/retrabalho, também seria possível olhar para os dados retroativamente. Seria prudente configurar um limite para que a partir de determinada data o serviço responsável por criar tais estatísticas tambem excluísse esses registros mais antigos.
    - Isso abriria portas para uma futura dashboard e gráficos que reportam as taxas de ocupação da pousada e de seus quartos.
  - Vale lembrar que isso é um projeto pequeno e que o dono da pousada Guava Inn dificilmente terá um volume tão grande de quartos a ponto de isso ser uma preocupação. Mas ficam aí as ideias de hoje.

17/07
- Enviado email para Guava para definir se implementação considerando metade de um dia no início e fim de reservas está correta. Isso impacta no cálculo caso haja uma interseção entre os dias sendo observados e reservas atravessando os extremos desse limite de observação.
- Recebida resposta. Implementação não estava correta. Agora, com melhor compreensão do problema será ajustado o algoritmo.
- Algoritmo de cálculo para taxa de ocupação finalizado.
- Testes de sistema de show room e index room finalizados. Inicialmente havia sido feito utilizando contextos diferentes, como:

  ```ruby
  context 'when there are reservations for the room on the next 7 or 30 days' do
    context 'when the room has a reservation happening in the next 7 days' do
      it 'shows 71% weekly occupancy rate'
      it 'shows 16% monthly occupancy rate'
    end

    context 'when the room has no reservations on the next 7 days but has for the next 30 days' do
      it 'shows 0% weekly occupancy rate'
      it 'shows 23% monthly occupancy rate'
    end

    context 'when the room has reservations for the next 7 days and for the next 30 days as well' do
      it 'shows 100% weekly occupancy rate'
      it 'shows 57% monthly occupancy rate'
    end
  end
  ```

  Mas pela complexidade adicional, a ideia foi abandonada. Ao invés disso apenas inseri novos `expect` nos testes que já eram generalistas o bastante sobre testar todos os detalhes da página de quarto quarto e da listagem.

- Configurada exibição com sucesso das taxas de ocupação na página de show.
- Longo estudo/pesquisa de como exibir as taxas de ocupação globais na parte de cima da página sem iterar pelo array de quartos uma segunda vez e chamar o método de cálculo de taxa de ocupação para cada quarto novamente. A principal dificuldade é que o array só é percorrido após os elementos que contém as taxas de ocupação globais já terem sido renderizados. O ideal seria aproveitar a "primeira passagem" no array.
- *Occupation* não é a palavra mais adequada, e sim *occupancy*. Refatorar. [Fonte.](https://wikidiff.com/occupation/occupancy)
- Optei por fazer a lógica no controller, na action `index`. Não está a coisa mais bonita do mundo, mas funciona. Pensar em como melhorar depois.

- Adicionados mais alguns testes e finalizada a parte de exibir dinamicamente a taxa de ocupação.

- Devido a uma epifania que levou a descoberta do callback `after_find`, a lógica do controller foi refatorada. Com `after_find`, agora todo model instanciado de 'Room' tem sua taxa de ocupação mensal e semanal calculada assim que é retirado do banco, que é então salva nos respectivos atributos virtuais. A action `index` do controller foi drasticamente reduzida e agora só obtem os elementos do banco e calcula as médias globais, disponibilizando na view.

  - Talvez seja uma boa colocar a função de calculo de taxa de ocupação como private? **NÃO É** - A função pode precisar ser chamada externamente no futuro com maior flexibilidade de datas.

- Milestones 1 e 2 atingidas antes do prazo esperado.



18/07
- Encontrado 'bug' em busca, quando data de inicio informada acontece após a data de fim, fazendo com que a busca ainda retorne resultados. Criada issue, adicionados testes e corrigido.
- Encontrado 'bug' em criação de quarto, que após criar em "Create Reservation" para aquele quarto específico, não mantém o quarto escolhido no dropdown de seleção de quarto. Na verdade é questionável até se o dropdown deveria existir, já que no menu anterior o usuário optou por criar reserva naquele quarto. Criada issue.
- Adicionados testes para contemplar correção do bug acima e outras coisas menores. Removido dropdown caso seja passado parâmetro de id do quarto.
- Notada a falta de validações em `code` e `notes` do model Room, o que pode levar a problemas de armazenamento e falhas (textos extensos demais). Adicionados testes e feita a implementação.
- Percebi que `to_i` não era o método mais adequado para converter as taxas de ocupação. Ao invés disso, usei `round`.
- Percebido bug em botão back na criação de reserva. Mais detalhes na issue #18
- Percebido bug (ou talvez  oportunidade de melhoria?) em dropdown de seleção de quantidade de hóspedes na criação de reserva. O dropdown não mostra valores que vão até a capacidade do quarto, mas sim valores fixos de 1 a 10. Isso pode causar confusão e levar a erros na criação do quarto que poderiam ser evitados.
- Configurado CircleCI, com jobs de build e test na pipeline. Futuramente, pode-se considerar adicionar um job de deploy.
- Por hoje é tudo, pessoal

19/07
  - Push de alguns commits para o trunk. CI acusa tudo ok.
  - Criei novo branch para gerenciar instalação e refatoração com factorybot
  - Coa parte do dia revisando/estudando factorybot para criar factories adequadas. Após vários experimentos, finalmente consegui.
  - Refatorados todos os testes para utilizarem as factories do factorybot. Foi um longo dia.

20/07
 - Hoje tive a ideia de colocar badges como wakatime, codecov e status de build. Wakatime é a mais fácil e direta, já configurei o projeto e falta ainda criar o readme. Codecov precisa de um trabalho a mais para integrar com circleci, que farei hoje
  - Lembrei que faltou a validação de comprimento no campo de nome de hóspede em reserva. Criada issue no zenhub e colocada como prioridade.
  - Escritos os testes para validação mencionada acima e implementada a validação.
  - Refatorado new.html.erb de reservation para utilizar partial, assim como new.html.erb de room faz.
  - Talvez seja relevante subir todos os branches locais que usei para desenvolvimento para o repositório. Por mais que eu goste de um repositório limpo, pode ajudar a visualizar o processo de desenvolvimento.
  - Adicionado simplecov, report de test coverage gerado a cada vez que a suite de testes é concluída, e salva na pasta `coverage/`, que também foi adicionada ao `.gitignore`. Tem alguns dados úteis para ver se a cobertura de testes está boa. Vale lembrar que cobertura de testes não diz nada sobre a qualidade deles, mas a métrica é boa e ajuda a observar se estamos testando o código amplamente. A modalidade ativada de branch coverage também é útil para verificar se estamos testando todas as possibilidades nas condicionais existentes no sistema. Infelizmente, ainda não consegui fazer funcionar com CircleCI de modo a enviar para o codecov para gerar uma badge e deixar os reports online. O CircleCI acusa executar as rotinas de upload mas o codecov não recebe.
  - Resto do dia focado em realizar o deploy. Conta criada na amazon AWS, e inicio do estudo de capistrano. Nunca usei nenhuma das duas tecnologias e achei a oportunidade boa para aprender.
  - Tive que excluir o arquivo encriptado secrets.yml.enc porque não possuia a master.key. Mas acredito que como o projeto era bem básico, não devia ter nada lá além do padrão. Gerei outro arquivo e outra master.key para poder usar no deploy.
  - Muitas tentativas e erros, pesquisa, configuração de arquivos, instalação de dependencias e afins, para conseguir fazer o capistrano funcionar, mas parece que finalmente tudo deu certo! `cap production deploy` roda sem problemas. Resta saber como posso dockerizar isso ou então apenas iniciar um servidor nginx.

21/07
  - A má noticia é que o servidor da AWS aparentemente bugou quando eu fui dar um reboot e nunca mais abriu a porta SSH. Perdi algumas horas tentando consertar mas desisti. AWS abortada, vou para o bom e velho digital ocean. A boa notícia é que consegui créditos promocionais no digital ocean para alugar uma máquina.
  - Também consegui um domínio gratuito guava-inn.tech, graças ao github student pack.
  - Ok, consegui acertar a configuração do capistrano, e fiz algumas melhorias. Coloquei credenciais do db no arquivo credentials.yml.enc.
  - Encontrei uma gem para o capistrano que integra puma e nginx e achei [este tutorial](https://coderwall.com/p/ttrhow/deploying-rails-app-using-nginx-puma-and-capistrano-3) que pretendo seguir pra terminar o deploy.
  - Depois de muitas tentativas e erros (inclusive alguns no proprio tutorial), problemas com o socket do puma, 62 abas abertas simultaneamente no Chrome... Guava Inn está oficialmente no ar!

  Lista de referências que consultei:
  - https://coderwall.com/p/ttrhow/deploying-rails-app-using-nginx-puma-and-capistrano-3
  - https://github.com/seuros/capistrano-puma/issues/188
  - https://github.com/seuros/capistrano-puma
  - https://stackoverflow.com/questions/43488432/puma-not-creating-socket-file-while-deployed-with-capistrano (no fim o problema disso era que após o puma utilizar a opção --daemonize ele ficava em segundo plano e não dava mais mensagens de erro. Quando rodei manualmente sem a opção --daemonize descobri que ele não iniciava pois não encontrava a pasta /log onde devia criar os arquivos de log. No fim, foi só criar a pasta.)
  - https://github.com/seuros/capistrano-puma/issues/188#issuecomment-346240812
  - https://capistranorb.com/
  - https://medium.com/@KerrySheldon/ec2-exercise-1-6-deploy-a-rails-app-to-an-ec2-instance-using-capistrano-3485238e4a4a
  - https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-puma-and-nginx-on-ubuntu-14-04
  - https://www.digitalocean.com/community/tutorials/deploying-a-rails-app-on-ubuntu-14-04-with-capistrano-nginx-and-puma
  - https://onebitcode.com/rails-5-2-credentials/
  - https://blog.engineyard.com/rails-encrypted-credentials-on-rails-5.2#:~:text=Your%20text%20editor%20will%20open,yml.
  - https://mirrorcommunications.com/blog/using-credentials-in-rails-5-2-for-your-database-and-user-password
  - https://stackoverflow.com/questions/22593657/capistrano-3-is-not-running-rails-migrations-when-deployed/27675931#27675931
  - https://github.com/capistrano/rails
  - Sim, foi outro longo dia.

22/07
  - Hoje cadastrei e resolvi a issue para corrigir o bug onde era possível alterar a capacidade do quarto com reservas existentes fazendo uso daquela capacidade.
    - Por algum motivo adicionar essa validation personalizada fez com que a factory não retornasse o objeto com as associações a menos que antes fosse feito um reload. Não entendi bem o porque apesar de ter pesquisado bastante, mas o comando `MODEL.reload` resolveu o problema.
  - Corrigido bug estético do `textarea` do `guest_name` na página de criar reserva que estava grande demais
  - Feito merge do branch com as configurações de deploy via capistrano no trunk
  - Feitas configurações de CD em CircleCI para automatizar deploy com capistrano.
  - Configurados certificados SSL com letsencrypt em produção com renovação automática via cronjob
  - Configuradas rotinas de logrotate

23/07
  - Hoje, dia de encerrar o ciclo de desenvolvimento referente ao CD. Squash de commits e merge em trunk.
  - Hoje, também dia de reorganização. Várias issues adicionadas referentes a melhorias pensadas para a plataforma, a maioria estética.
  - Organizadas labels do repositório e colocado labels em todas issues para melhor separação de contextos.
  - Retomada da implementação com codecov. Dessa vez encontrada a gem [codecov-ruby](https://github.com/codecov/codecov-ruby) que parece promissora para ajudar no upload que até então não está funcionando.
  - Implementação do upload para codecov com CircleCI bem sucedida!
  - Iniciei o trabalho em algumas melhorias estéticas na listagem de quartos e na exibição das reservas do quarto
  - Criei branch para trabalhar em feature de envio de email. A gem do mailgun provavelmente não será necessária visto que eles dão suporte a SMTP, que é mais simples.
  - Feito credenciamento no site da mailgun com o dominio guava-inn.tech.

24/07
  - Criado layout básico de email
  - Feitos os testes unitários, de sistema e toda a implementação do envio de email

25/07
  - Problema utilizando as credentials.yml.enc. Antes, havia feito configurações para development, então a senha não estava sendo utilizada no DB (estava conectando no postgres por peer authentication. Encontrei explicação melhor [aqui](https://stackoverflow.com/a/15308493)). Após corrigir o arquivo credentials.yml.enc, o deploy parou de ser feito através do usuário 'deploy' que era automaticamente autorizado pelo postgres.
  - Corrigido problema adicionando 'host: localhost' no arquivo database.yml, para fazer com que o postgres não use peer authentication mas sim password authentication.
  - Corrigido erro em requisições não-GET em produção devido a token de autenticação inválido. Faltavam headers no nginx como mostrado [aqui](https://stackoverflow.com/a/51111144) e [nessa issue do rails](https://github.com/rails/rails/issues/22965).
  - Resto do dia trabalhando com design da página `rooms#index`. Utilizado bootstrap e material design icons.
  - Design finalizado, testes de sistema refatorados para refletir as alterações feitas na interface.

26/07
  - Retomada no design das páginas que faltam. Mudar o mínimo possível da estrutura original para evitar de quebrar testes.
  - Finalizado design de todas as páginas. Todos os testes ok.
  - Encontrado bug onde após criar uma reserva inválida (sem nome do hóspede, por exemplo) e atualizar o browser com F5, a request feita é um GET para /reservations, que não existe. Algumas soluções foram tentadas sem sucesso, mas após uma pesquisa, descobri que o buraco é mais embaixo: se trata de um [bug do turbolinks](https://github.com/turbolinks/turbolinks/issues/60) relacionado ao refresh da página que possui um [fix que ainda não teve o merge feito](https://github.com/turbolinks/turbolinks/pull/495) na branch principal.
  - Feitas algumas modificações estéticas para enriquecer as informações mostradas em algumas telas
  - Implementada feature que permite a consulta da taxa de ocupação em qualquer período válido desejado
  - Finalização da escrita deste diário para entrega do projeto.
