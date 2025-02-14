module namespace page = 'http://basex.org/examples/web-page';
 
declare default element namespace 'http://projeto.pei.estg/2022/Marcacoes';

declare namespace peritagem = 'http://projeto.pei.estg/2022/Peritagens';


(:funçao que chama a validaçao e adicionar marcacao:)
declare
  %updating  
  %rest:path("marcacao")
  %rest:POST("{$marcacao}")
  %rest:consumes('application/xml')
function page:addMarcacao($marcacao as item())
{
  page:validateXMLmarcacao($marcacao),
  let $exists := fn:count(db:get("projetoDB")//marcacao[Codigo_marcacao = $marcacao//Codigo_marcacao])
  return (
        if($exists = 0) then 
           page:addMarcacao2($marcacao)
        else
           update:output(web:redirect('/app/409'))
  )
};

(:adiciona o xml a base de dados:)
declare 
%updating 
function page:addMarcacao2($marcacao){
    let $newId := fn:count(db:get("projetoDB")//marcacao) + 1
    let $newdocument := $marcacao
                          
    return(
            db:add("projetoDB", $newdocument, fn:concat("marcacao", $newId , ".xml")),
            update:output(web:redirect(concat('/app/201/',$newId)))
          )
};

(:valida com o xsd o xml a ser adicionado:)
declare 
  %updating 
  function page:validateXMLmarcacao($marcacao as node()){
  let $xsd:= "./projeto/Marcacoes.xsd"
  return validate:xsd($marcacao, $xsd)
};

(:apresenta todas as marcacoes do dia de um certo perito:)
declare 
  %rest:path("/findMarcacoes/{$Id_Perito}")
  %rest:GET
 function page:findMarcacoes($Id_Perito) {
   let $currentDate := format-date(current-date(), "[Y0001]-[M01]-[D01]")
   let $exists := db:get("projetoDB")//marcacao[Id_Perito = $Id_Perito][date = $currentDate]
   return (if ($exists) then 
   $exists else
   <rest:response>
     <http:response
     status="404"></http:response>
   </rest:response>
    )
 };
 
 (:funcao que chama a validaçao e adicionar(se existir um perito,parceiro e verifica se ja existe):)
 declare
  %updating  
  %rest:path("peritagem")
  %rest:POST("{$peritagem}")
  %rest:consumes('application/xml')
function page:addPeritagem($peritagem as item())
{
  page:validateXMLperitagem($peritagem),
  let $exists := fn:count(db:get("projetoDB")//marcacao[Codigo_marcacao] = $peritagem//peritagem:Codigo)
  let $parceiro:= fn:count(db:get("projetoDB")//parceiro[Id_parceiro] = $peritagem//peritagem:Id_parceiro)
  let $perito:= fn:count(db:get("projetoDB")//perito[Id_perito] = $peritagem//peritagem:Id_perito)
  return (
        if($exists = 1 and $parceiro = 1 and $perito = 1) then 
           page:addPeritagem2($peritagem)
        else
           update:output(web:redirect('/app/409'))
  )
};

(:adiciona a base de dados a peritagem xml proposta:)
declare 
%updating 
function page:addPeritagem2($peritagem){
    let $newId := fn:count(db:get("projetoDB")//peritagem) + 1
    let $newdocument := $peritagem
    return(
            db:add("projetoDB", $newdocument, fn:concat("peritagem", $newId , ".xml")),
            update:output(web:redirect(concat('/app/201/',$newId)))
          )
};


(:valida com o xsd se o xml segue as regras:)
declare 
  %updating 
  function page:validateXMLperitagem($peritagem as node()){
  let $xsd:= "./projeto/Peritagens.xsd"
  return validate:xsd($peritagem, $xsd)
};
 
 
(:devolve a peritagem que tiver o codigo procurado nas peritagens da base de dados:)
declare
 %rest:path("peritagem/{$codigoPeritagem}")
 %rest:GET
 function page:seePeritagem($codigoPeritagem as xs:integer){
   let $exists := db:get("projetoDB")//peritagem[Codigo = $codigoPeritagem]
   return (if ($exists) then
     $exists
   else 
     <rest:response>
       <http:response
       status="404"></http:response>
     </rest:response>
   )
 };
 
 
 (:devolve as peritagens de um certo dia de um parceiro:)
declare
 %rest:query-param ("Dia", "{$Dia}")
 %rest:path("peritagem/ver/{$Id_parceiro}")
 %rest:GET
 %rest:consumes('application/xml')
 function page:seePeritagens($Dia, $Id_parceiro){
   let $exists := db:get("projetoDB")//peritagem[Dia = $Dia][Id_parceiro =$Id_parceiro]
   return (if ($exists ) then 
     $exists 
   else 
     <rest:response>
       <http:response
       status="404"></http:response>
     </rest:response>
   )
 };

(:reescreve o ficheiro da base de dados onde o codigo equivaler,o perito e o parceiro:)
declare
%updating
  %rest:path("peritagem/alterar")
  %rest:PUT("{$peritagem}")
  %rest:consumes('application/xml')
 function page:alterar($peritagem){
   page:validateXMLperitagem($peritagem),
   let $exists := fn:count(db:get("projetoDB")//marcacao[Codigo_marcacao = $peritagem//peritagem:Codigo])
   let $parceiro:= fn:count(db:get("projetoDB")//parceiro[Id_parceiro = $peritagem//peritagem:Id_parceiro])
   let $perito:= fn:count(db:get("projetoDB")//perito[Id_perito = $peritagem//peritagem:Id_perito])
   let $newdocument := element peritagens{
     db:get("projetoDB")//peritagem:peritagem[peritagem:Codigo != $peritagem//peritagem:Codigo][peritagem:Dia != $peritagem//peritagem:Dia],
     $peritagem//peritagem:peritagem
   }
   
   return ( if($exists = 1 and $parceiro = 1 and $perito = 1) then 
             db:add("projetoDB", $newdocument, "peritagens.xml")
            else
             update:output(web:redirect('/app/409')))
 };