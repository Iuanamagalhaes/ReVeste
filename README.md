# ReVeste

**Aplicativo para Descoberta de Brechós**

![Preview da aplicação](./assets_readme/pagina_inicial.png)

## Sobre o projeto

A ReVeste é um aplicativo de moda circular que aproxima consumidores e brechós profissionais. A proposta nasce da percepção de que muitas lojas desse segmento divulgam suas peças de forma fragmentada, principalmente por redes sociais, mensagens e publicações temporárias, o que dificulta, para quem quer comprar roupas de segunda mão, encontrar estabelecimentos próximos, conhecer o estilo de cada loja e consultar as peças disponíveis antes de se deslocar.

O app reúne localização, catálogo e contato em um único ambiente: o consumidor descobre brechós por localização (ou por região informada manualmente), acessa perfis de lojas, pesquisa produtos, aplica filtros e salva itens de interesse; o brechó mantém um perfil comercial e cadastra as peças que deseja divulgar.

O projeto está sendo construído em **Flutter**, ao longo dos Checkpoints 4, 5 e 6.

## Proposta de valor

A ReVeste torna a procura por roupas de segunda mão mais organizada, aproximando consumidores de brechós da sua região e permitindo conhecer as lojas antes de visitá-las.

- **Para o consumidor:** economia de tempo e mais chances de encontrar peças compatíveis com estilo, tamanho e orçamento, sem precisar alternar entre redes sociais, mapas e mensagens.
- **Para o brechó:** maior visibilidade entre pessoas que já têm interesse nesse tipo de compra, com um catálogo apresentado de forma clara, sem substituir os canais que a loja já utiliza.

## Objetivo geral

Desenvolver uma aplicação multiplataforma em Flutter capaz de conectar consumidores e brechós profissionais, facilitando a descoberta de lojas, a consulta de produtos e o início do processo de compra.


## Identidade visual (proposta inicial)

| Cor | Código | Aplicação sugerida |
|---|---|---|
| Verde escuro | `#355E4B` | Cor principal, botões e elementos de destaque |
| Creme | `#F7F2E8` | Fundos claros e áreas de respiro |
| Terracota | `#C96F4A` | Destaques secundários e etiquetas |
| Verde sálvia | `#A9BFAF` | Cards e elementos de apoio |
| Grafite esverdeado | `#22352D` | Textos e ícones de maior contraste |
| Branco | `#FFFFFF` | Fundos, superfícies e contraste |

##  Integrantes do grupo

| Nome | RM |
|---|---|
| Bernardo Silva Berwanger | RM565776 |
| João Vitor Angeloti Sena | RM563473 |
| Laís Krajner Lacerda | RM563182 |
| Luana Magalhães Freire | RM565305 |
| Pamella Souza da Silva Ferreira | RM566172 |

Link do Figma: https://www.figma.com/design/j254jze0orFy3FMuPbmGqL/CheckPoint-04---CPAD?node-id=0-1&t=wyqk9D4hTnVJuCpF-1

---

## Como rodar (CP5)

Pré-requisitos: Flutter instalado e o projeto Firebase `banco-dados-revest` já configurado (`lib/firebase_options.dart`).

```bash
cd reveste
flutter pub add firebase_storage image_picker url_launcher http   # só na primeira vez
flutter pub get
flutter run -d chrome        # ou: flutter run  (emulador Android)
```

No console do Firebase:
1. **Authentication > Método de login:** ativar *E-mail/senha*.
2. **Firestore > Regras:** colar `reveste/firebase_rules/firestore.rules` e publicar.
3. **Storage > Regras:** colar `reveste/firebase_rules/storage.rules` e publicar (veja "Imagens" abaixo).
4. **Authentication > Modelos:** (opcional) traduzir o e-mail de verificação para português.

## Decisões técnicas

- **Verificação de e-mail real:** o Firebase Auth envia um *link* de confirmação (não existe código numérico nativo). A tela de verificação confere o status a cada 3 s e avança sozinha; há reenvio com intervalo de 30 s. `AuthService.exigirVerificacao = false` desliga a exigência (útil para contas de teste criadas no console).
- **Sessão persistente:** `AuthGate` reabre o app já logado, no fluxo certo (verificação, estilos ou home).
- **Imagens:** em todos os casos o que fica no Firestore é um texto: `users.foto_url`, `stores.logo_url`, `stores.capa_url` e `products.imagens[]`. O host é escolhido em `ImageConfig.host` (`lib/services/image_upload_service.dart`), padrão `auto`:
  - **Cloudinary** (gratuito, sem cartão): se `cloudinaryCloudName` e `cloudinaryUploadPreset` estiverem preenchidos (preset *unsigned*), a foto vai para o Cloudinary e o **link https** é gravado no Firestore.
  - **Firestore inline** (sem configurar nada): a foto é reduzida (~800 px, até ~110 KB) e gravada no próprio Firestore como data-URL.
  - **Firebase Storage**: desde fev/2026 exige o plano Blaze (cartão). Sem ele o envio nunca responde — era isso que deixava o app "carregando". Todo envio agora tem timeout de 30 s e mostra erro.
- **Compra dentro do app:** o carrinho tem "Comprar e pagar" por brechó (entrega ou retirada; Pix, cartão ou pagar na retirada). O **pagamento é simulado** (nenhum dado de cartão é enviado ou gravado). O pedido é gravado em `orders` e as peças são marcadas como vendidas (`disponivel: false`, `vendido: true`) na **mesma transação**, evitando vender a mesma peça duas vezes.
- **Pedidos do brechó:** aba *Pedidos* com andamento (pago → em preparo → pronto/enviado → concluído) e cancelamento, que devolve as peças ao catálogo.
- **Contato dentro do app (chat):** coleção `chats/{consumidorId_storeId}` com subcoleção `messages`, em tempo real. Consumidor: ícone de conversa na peça, botão *Mensagem* no perfil do brechó, *Perfil > Mensagens*. Brechó: aba *Mensagens*. O WhatsApp foi removido do fluxo.
- **Filtros no app (client-side):** categoria, estilo da loja, tamanho, faixa de preço e texto, sem exigir índices compostos no Firestore.
- **Regras do Firestore:** qualquer usuário logado lê/escreve (exceto `categories`, só leitura). Regras por dono quebrariam os usuários mockados.

## Estrutura de pastas (`reveste/lib`)

```
models/      AppUser, Store, Product, Category, Pedido, Conversa/Mensagem
services/    auth, firestore (pedidos e chat), image_upload
state/       cart (carrinho em memória)
screens/     auth/ · consumer/ (checkout, compras) · brecho/ · store/ · chat/
widgets/     componentes reutilizáveis
theme/       cores e fontes
```

## Papéis de cada integrante

| Nome | RM | Papel |
|---|---|---|
| Bernardo Silva Berwanger | RM565776 | (preencher) |
| João Vitor Angeloti Sena | RM563473 | (preencher) |
| Laís Krajner Lacerda | RM563182 | (preencher) |
| Luana Magalhães Freire | RM565305 | (preencher) |
| Pamella Souza da Silva Ferreira | RM566172 | (preencher) |
