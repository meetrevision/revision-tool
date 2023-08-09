import 'localizations.dart';

/// The translations for Portuguese (`pt`).
class ReviLocalizationsPt extends ReviLocalizations {
  ReviLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get unsupportedTitle => 'Erro';

  @override
  String get unsupportedContent => 'Versão incompatível!';

  @override
  String get okButton => 'OK';

  @override
  String get notNowButton => 'Agora não';

  @override
  String get restartDialog => 'Você deve reiniciar o computador para que as alterações surtam efeito.';

  @override
  String get moreInformation => 'Mais informações';

  @override
  String get onStatus => 'Ativado';

  @override
  String get offStatus => 'Desativado';

  @override
  String get pageHome => 'Início';

  @override
  String get pageSecurity => 'Segurança';

  @override
  String get pageUsability => 'Usabilidade';

  @override
  String get pagePerformance => 'Desempenho';

  @override
  String get pageUpdates => 'Windows Update';

  @override
  String get pageMiscellaneous => 'Outros';

  @override
  String get pageSettings => 'Configurações';

  @override
  String get suggestionBoxPlaceholder => 'Pesquisar';

  @override
  String get homeWelcome => 'Bem-vindo(a) ao Revision';

  @override
  String get homeDescription => 'Uma ferramenta para personalizar o ReviOS de acordo com suas necessidades.';

  @override
  String get homeReviLink => 'Visite nosso site';

  @override
  String get homeReviFAQLink => 'Perguntas Frequentes';

  @override
  String get securityWDLabel => 'Windows Defender';

  @override
  String get securityWDDescription => 'O Windows Defender protegerá seu PC. Isso terá um impacto no desempenho devido à sua execução constante em segundo plano.';

  @override
  String get securityWDButton => 'Desativar proteções';

  @override
  String get securityDialog => 'Por favor, desative todas as proteções antes de desativar completamente o Windows Defender.';

  @override
  String get securityUACLabel => 'Controle de Conta de Usuário';

  @override
  String get securityUACDescription => 'Limita a aplicação a privilégios de usuário padrão até que um administrador autorize uma elevação.';

  @override
  String get securitySMLabel => 'Mitigação do Spectre e Meltdown';

  @override
  String get securitySMDescription => 'Patches para habilitar a mitigação contra as vulnerabilidades do Spectre e Meltdown.';

  @override
  String get usabilityNotifLabel => 'Notificações do Windows';

  @override
  String get usabilityNotifDescription => 'Desativar completamente as notificações do Windows.';

  @override
  String get usabilityLBNLabel => 'Estilo de Notificação Antigo';

  @override
  String get usabilityLBNDescription => 'Programas da bandeja na barra de tarefas serão exibidos como balões em vez de notificações toasts.';

  @override
  String get usabilityITPLabel => 'Personalização de Escrita e Digitação';

  @override
  String get usabilityITPDescription => 'O Windows aprenderá o que você digita para aprimorar as sugestões ao escrever.';

  @override
  String get usabilityCPLLabel => 'Desativar a tecla Caps Lock';

  @override
  String get usability11MRCLabel => 'Novo Menu de Contexto';

  @override
  String get usability11FETLabel => 'Guias no Explorador de Arquivos';

  @override
  String get perfSuperfetchLabel => 'Superfetch';

  @override
  String get perfSuperfetchDescription => 'Acelere o tempo de inicialização e carregue os programas mais rapidamente pré-carregando todos os dados necessários na memória. Habilitar o Superfetch é recomendado apenas para usuários de HDD (disco rígido).';

  @override
  String get perfMCLabel => 'Compactação de Memória';

  @override
  String get perfMCDescription => 'Economize memória comprimindo programas não utilizados em execução em segundo plano. Pode ter um pequeno impacto no uso da CPU, dependendo do hardware.';

  @override
  String get perfITSXLabel => 'Intel TSX';

  @override
  String get perfITSXDescription => 'Adicionar suporte a memória transacional de hardware, o que ajuda a acelerar a execução de software multithread em detrimento da segurança.';

  @override
  String get perfFOLabel => 'Otimizações em Tela Cheia';

  @override
  String get perfFODescription => 'As \'Otimizações em Tela Cheia\' podem levar a um melhor desempenho de jogos e aplicativos ao serem executados em modo de tela cheia.';

  @override
  String get perfOWGLabel => 'Otimizações em modo de janela';

  @override
  String get perfOWGDescription => 'Melhora a latência de quadros ao utilizar um novo modelo de apresentação para jogos DirectX 10 e 11 que são executados em uma janela ou em uma janela sem bordas.';

  @override
  String get perfCStatesLabel => 'Desative os estados ACPI C2 e C3';

  @override
  String get perfCStatesDescription => 'Desativar os estados C do ACPI pode melhorar o desempenho e a latência, mas consumirá mais energia em repouso, o que pode reduzir a vida útil da bateria.';

  @override
  String get perfSectionFS => 'Sistema de Arquivos';

  @override
  String get perfLTALabel => 'Desativar o registro do último horário de acesso';

  @override
  String get perfLTADescription => 'Desativar o registro do último horário de acesso melhora o desempenho do acesso a arquivos e diretórios, reduz a carga de E/S no disco e a latência.';

  @override
  String get perfEdTLabel => 'Desativar a nomenclatura 8.3';

  @override
  String get perfEdTDescription => 'A nomenclatura 8.3 é antiga e desativá-la irá melhorar o desempenho e a segurança do NTFS.';

  @override
  String get perfMULabel => 'Aumente o limite de memória de pool paginado para o NTFS';

  @override
  String get perfMUDescription => 'Aumentar a memória física nem sempre aumenta a quantidade de memória de pool paginado disponível para o NTFS. Definir \'memoryusage\' para 2 eleva o limite de memória de pool paginado. Isso pode melhorar o desempenho se o seu sistema estiver abrindo e fechando muitos arquivos no mesmo conjunto de arquivos e não estiver usando grandes quantidades de memória do sistema para outros aplicativos ou para memória cache. Se o seu computador já estiver usando grandes quantidades de memória do sistema para outros aplicativos ou para memória cache, aumentar o limite de memória de pool paginado e não paginado do NTFS reduz a memória de pool disponível para outros processos. Isso pode reduzir o desempenho geral do sistema.\n\nDesativado por padrão.';

  @override
  String get wuPageLabel => 'Ocultar a página de atualizações do Windows';

  @override
  String get wuPageDescription => 'Mostrar esta página também habilitará notificações de atualizações';

  @override
  String get wuDriversLabel => 'Drivers instalados através do Windows Update';

  @override
  String get wuDriversDescription => 'Para instalar drivers no ReviOS, você precisa verificar manualmente as atualizações em Configurações, pois as atualizações automáticas do Windows não são suportadas';

  @override
  String get miscHibernateLabel => 'Hibernate';

  @override
  String get miscHibernateDescription => 'Um estado de economia de energia S4, salva a sessão atual no hiberfile e desliga o dispositivo. Desabilitado por padrão para evitar instabilidade durante o dual-boot ou atualizações do sistema';

  @override
  String get miscHibernateModeLabel => 'Modo de Hibernação';

  @override
  String get miscHibernateModeDescription => 'Completo - Suporta hibernação e inicialização rápida. O hiberfile será 40% da RAM física instalada. A hibernação estará disponível no menu de energia.\n\nReduzido - Suporta apenas a Inicialização Rápida sem hibernação, o hiberfile será 20% da RAM física instalada e remove a hibernação do menu de energia';

  @override
  String get miscFastStartupLabel => 'Inicialização Rápida';

  @override
  String get miscFastStartupDescription => 'Salva a sessão atual em C:\\hiberfil.sys para inicialização mais rápida, não afeta os reinícios. Desabilitado por padrão para evitar instabilidade durante o dual-boot ou atualizações do sistema';

  @override
  String get miscTMMonitoringLabel => 'Monitoramento de Rede e GPU';

  @override
  String get miscTMMonitoringDescription => 'Ativa os serviços de monitoramento para o Gerenciador de Tarefas';

  @override
  String get miscMpoLabel => 'Overlay Multiplane (MPO)';

  @override
  String get miscMpoCodeSnippet => 'Recomendado desativar em placas Nvidia GTX 16xx, RTX 3xxx e AMD RX 5xxx ou mais recentes.\nDeixar isso ativado pode causar telas pretas, travamentos, cintilações e outros problemas gerais de exibição';

  @override
  String get miscBHRLabel => 'Relatório de Saúde da Bateria';

  @override
  String get miscBHRDescription => 'Relata o estado da saúde da bateria; Habilitar isso aumentará o uso do sistema';

  @override
  String get miscCertsLabel => 'Atualizar Certificados Raiz';

  @override
  String get miscCertsDescription => 'Use quando tiver problemas com certificados';

  @override
  String get miscCertsDialog => 'A atualização dos certificados raiz foi concluída. Tente o software com o qual você teve problemas novamente e, se o problema persistir, entre em contato com nosso suporte.';

  @override
  String get settingsUpdateLabel => 'Atualizar RevisionTool';

  @override
  String get updateButton => 'Atualizar';

  @override
  String get settingsUpdateButton => 'Verificar Atualizações';

  @override
  String get settingsUpdateButtonAvailable => 'Atualização Disponível';

  @override
  String get settingsUpdateButtonAvailablePrompt => 'Você deseja atualizar a Ferramenta Revision para';

  @override
  String get settingsUpdatingStatus => 'Atualizando';

  @override
  String get settingsUpdatingStatusSuccess => 'Atualizado com sucesso';

  @override
  String get settingsUpdatingStatusNotFound => 'Nenhuma atualização encontrada';

  @override
  String get settingsCTLabel => 'Tema de Cores';

  @override
  String get settingsCTDescription => 'Alterne entre os modos claro e escuro, ou alterne automaticamente o tema com o Windows';

  @override
  String get settingsEPTLabel => 'Mostrar ajustes experimentais';

  @override
  String get settingsEPTDescription => '';

  @override
  String get restartAppDialog => 'Você precisa reiniciar o aplicativo para que as alterações tenham efeito.';

  @override
  String get settingsLanguageLabel => 'Idioma';
}
