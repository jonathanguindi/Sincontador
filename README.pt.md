# SinApuestas 🛡️  (Português)

Uma ferramenta de apoio para **parar de apostar**: bloqueia apps e sites de
apostas no seu **celular (Android e iPhone)** e no seu **computador**. Sem VPN.
Feita para ser **o mais difícil possível de desativar** num impulso, com uma
senha ou código que idealmente fica com alguém de confiança, e um "período de
compromisso" que não dá para encurtar.

> É uma ferramenta de apoio, não um tratamento. Se as apostas estão te fazendo
> mal, combine com ajuda de verdade (veja o final).

## O que tem neste repositório

| Pasta | Para | Como bloqueia |
|---|---|---|
| `android/` | App Android (Kotlin) | Serviço de **Acessibilidade** + **Administrador do dispositivo**. Bloqueia apps e sites de apostas e se defende de ser desinstalado. |
| `apple/` | iPhone / iPad | Perfil de configuração com filtro web + app nativo com **Tempo de Uso / Family Controls**. |
| `desktop/` | Windows / macOS / Linux (Python) | Arquivo **hosts** do sistema + um vigia que o repara. |
| `blocklists/` | Listas mestras | Domínios, pacotes e palavras-chave de apostas, editáveis. |

## Como funciona a "tranca" (em todas as plataformas)

1. Você define uma **senha / código** — o ideal é que **outra pessoa** digite e
   guarde em segredo.
2. Você escolhe um **período de compromisso** (7, 30, 90 dias ou um ano).
3. Durante esse período o bloqueio **não pode ser desativado**, nem com a senha.
   Depois, a senha é necessária para remover.

## Bloqueio mundial

Duas camadas: uma lista com **centenas de casas de apostas** de todos os
continentes, mais uma **camada de palavras-chave** (casino, aposta, poker,
roleta, slots, bingo…) que pega também as novas ou fora da lista. No computador,
`update_worldwide.py` junta listas públicas gigantes para cobertura máxima.

## Como começar

- **Android:** abra `android/` no Android Studio, instale o app, defina a senha,
  escolha os dias e aprove as 2 permissões que ele pede.
- **iPhone:** siga `apple/README.md` — o caminho recomendado não precisa
  programar.
- **Computador:** vá em `desktop/`, siga `desktop/README.md` (um comando por SO).

## Sinceridade sobre os limites

Sem root/jailbreak, nada é 100% impossível de remover para quem tem permissões
de administrador e tempo. O que estas ferramentas conseguem é **fricção
suficiente** para frear o impulso — principalmente se a senha ficar com **outra
pessoa**, o período for **longo**, e no computador você usar uma conta **sem
administrador**. Nenhum app **fecha suas contas** numa casa de apostas — isso é
a **autoexclusão**.

## Se as apostas estão te fazendo mal

- **Autoexclusão** em cada operador onde você tem conta.
- **Bloqueio de pagamentos** de jogo (código MCC 7995): muitos bancos permitem.
- **Jogadores Anônimos**: jogadoresanonimos.org.br

## Licença

MIT — use, mude e compartilhe livremente. Que ajude alguém. 💙
