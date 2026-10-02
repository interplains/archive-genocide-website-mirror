/* Daily Reports — renders the running day-by-day war log. English uses the inline
   #reportData JSON; a language subtree (/ar/, /es/, …) loads /reports_<lang>.json
   (same shape, translated `body` lines) and falls back to the inline English if that
   file is missing. Kept external so the strict CSP (script-src 'self') allows it.
   Each card's "View footage" link deep-links into the gallery via ?from=&to=. */
(function(){
  var KNOWN=['el','ar','fr','de','ms','zh','es','pt','ja','ru','tr','it','ko','he','ta','te','uk','sw','pa','ro','sv','hr','tl','fa','pl'];
  var LANG=(function(){var m=location.pathname.match(/^\/([a-z]{2})(\/|$)/);return (m&&KNOWN.indexOf(m[1])>-1)?m[1]:'en';})();
  // UI chrome rendered by this script (the report bodies come translated in reports_<lang>.json).
  // %d/%s are filled at use; keep them verbatim.
  var RT={
    en:{reports:'reports',day:'DAY %d',footage:'View footage from this day',gap:'%d days not yet archived',nomatch:'No reports match “%s”.'},
    ku:{reports:"rapor",day:"ROJ %d",footage:"Dîmenên vê rojê bibîne",gap:"%d roj hê nehatine arşîvkirin",nomatch:"Tu rapor bi “%s” re naguncînin."},
    el:{reports:'αναφορές',day:'ΗΜΕΡΑ %d',footage:'Δείτε υλικό από αυτήν την ημέρα',gap:'%d ημέρες δεν έχουν αρχειοθετηθεί ακόμη',nomatch:'Καμία αναφορά δεν ταιριάζει με «%s».'},
    ar:{reports:'تقارير',day:'يوم %d',footage:'شاهد اللقطات من هذا اليوم',gap:'%d يوم لم تُؤرشف بعد',nomatch:'لا توجد تقارير تطابق «%s».'},
    fr:{reports:'rapports',day:'JOUR %d',footage:'Voir les images de ce jour',gap:'%d jours pas encore archivés',nomatch:'Aucun rapport ne correspond à « %s ».'},
    de:{reports:'Berichte',day:'TAG %d',footage:'Aufnahmen von diesem Tag ansehen',gap:'%d Tage noch nicht archiviert',nomatch:'Keine Berichte für „%s“.'},
    ms:{reports:'laporan',day:'HARI %d',footage:'Lihat rakaman hari ini',gap:'%d hari belum diarkibkan',nomatch:'Tiada laporan sepadan dengan “%s”.'},
    zh:{reports:'篇报告',day:'第 %d 天',footage:'查看当天影像',gap:'%d 天尚未存档',nomatch:'没有与“%s”匹配的报告。'},
    es:{reports:'informes',day:'DÍA %d',footage:'Ver imágenes de este día',gap:'%d días aún no archivados',nomatch:'Ningún informe coincide con «%s».'},
    ja:{reports:"報告書",day:"DAY %d",footage:"この日の映像を閲覧",gap:"%d日分未アーカイブ",nomatch:"「%s」に一致する報告書はありません。"},
    ru:{reports:"отчёты",day:"ДЕНЬ %d",footage:"Просмотреть кадры этого дня",gap:"%d дней ещё не архивированы",nomatch:"Нет отчётов, соответствующих «%s»."},
    tr:{reports:"raporlar",day:"GÜN %d",footage:"Bu güne ait görüntüleri görüntüle",gap:"%d gün henüz arşivlenmedi",nomatch:"“%s” ile eşleşen rapor yok."},
    it:{reports:"report",day:"GIORNO %d",footage:"Visualizza le riprese di questo giorno",gap:"Giorni %d non ancora archiviati",nomatch:"Nessun report corrisponde a “%s”."},
    ko:{reports:"보고서",day:"%d일차",footage:"이 날짜의 영상 보기",gap:"%d일이 아직 기록되지 않음",nomatch:"“%s”와 일치하는 보고서가 없습니다."},
    he:{reports:"דיווחים",day:"יום %d",footage:"צפה בתיעוד מיום זה",gap:"%d ימים שטרם אורכבו",nomatch:"אין דיווחים התואמים ל״%s״."},
ta:{reports:"அறிக்கைகள்",day:"நாள் %d",footage:"இந்த நாளின் காட்சிகளைப் பார்க்கவும்",gap:"%d நாட்கள் இன்னும் காப்பகப்படுத்தப்படவில்லை",nomatch:"“%s” உடன் பொருந்தும் அறிக்கைகள் எதுவும் இல்லை."},
    te:{reports:"నివేదికలు",day:"రోజు %d",footage:"ఈ రోజు నుండి దృశ్యాలను చూడండి",gap:"%d రోజులు ఇంకా ఆర్కైవ్ చేయబడలేదు",nomatch:"“%s”కి సరిపోలే నివేదికలు లేవు."},
    uk:{reports:"звіти",day:"ДЕНЬ %d",footage:"Переглянути відеоматеріали цього дня",gap:"%d днів ще не архівовано",nomatch:"Жодних звітів не відповідає «%s»."},
    sw:{reports:"ripoti",day:"SIKU %d",footage:"Tazama video za siku hii",gap:"Siku %d bado hazijahifadhiwa",nomatch:"Hakuna ripoti zinazolingana na “%s”."},
    pa:{reports:"ਰਿਪੋਰਟਾਂ",day:"ਦਿਨ %d",footage:"ਇਸ ਦਿਨ ਦੀ ਫੁਟੇਜ ਦੇਖੋ",gap:"%d ਦਿਨ ਅਜੇ ਤੱਕ ਸੰਗ੍ਰਹਿਤ ਨਹੀਂ ਹਨ",nomatch:"ਕੋਈ ਰਿਪੋਰਟ “%s” ਨਾਲ ਮੇਲ ਨਹੀਂ ਖਾਂਦੀ।"},
    ro:{reports:"rapoarte",day:"ZIUA %d",footage:"Vizualizați filmările din această zi",gap:"%d zile neînregistrate încă",nomatch:"Niciun raport nu corespunde cu „%s”."},
    pt:{reports:'relatórios',day:'DIA %d',footage:'Ver imagens deste dia',gap:'%d dias ainda não arquivados',nomatch:'Nenhum relatório corresponde a “%s”.'},
    sv:{reports:"rapporter",day:"DAG %d",footage:"Visa bildmaterial från denna dag",gap:"%d dagar ännu inte arkiverade",nomatch:"Inga rapporter matchar “%s”."},
    hr:{reports:"izvješća",day:"DAN %d",footage:"Pogledaj snimke s ovog dana",gap:"%d dana još nije arhivirano",nomatch:"Nijedno izvješće ne odgovara „%s”."},
    tl:{reports:"mga ulat",day:"ARAW %d",footage:"Tingnan ang mga footage mula sa araw na ito",gap:"%d araw na hindi pa na-archive",nomatch:"Walang mga ulat na tumutugma sa “%s”."},
    fa:{reports:"گزارش‌ها",day:"روز %d",footage:"مشاهده فیلم‌های این روز",gap:"%d روز هنوز بایگانی نشده است",nomatch:"هیچ گزارشی با «%s» مطابقت ندارد."},
    pl:{reports:"raporty",day:"DZIEŃ %d",footage:"Zobacz materiał z tego dnia",gap:"%d dni nie zostało jeszcze zarchiwizowanych",nomatch:"Brak raportów odpowiadających „%s”."},
  };
  function RTT(k){return (RT[LANG]&&RT[LANG][k]!=null)?RT[LANG][k]:RT.en[k];}
  var inline=JSON.parse(document.getElementById('reportData').textContent);

  var MONTHS=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  var DOWS=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  function parseISO(s){var p=s.split('-');return new Date(Date.UTC(+p[0],+p[1]-1,+p[2]));}
  function pad2(n){return (n<10?'0':'')+n;}
  function shiftISO(iso,delta){var d=parseISO(iso);d.setUTCDate(d.getUTCDate()+delta);return d.getUTCFullYear()+'-'+pad2(d.getUTCMonth()+1)+'-'+pad2(d.getUTCDate());}
  function fmtDate(iso){var d=parseISO(iso);return DOWS[d.getUTCDay()]+' · '+MONTHS[d.getUTCMonth()]+' '+d.getUTCDate()+', '+d.getUTCFullYear();}
  function fmtSpan(a,b){var x=parseISO(a),y=parseISO(b);return MONTHS[x.getUTCMonth()]+' '+x.getUTCFullYear()+' – '+MONTHS[y.getUTCMonth()]+' '+y.getUTCFullYear();}
  function esc(s){return s.replace(/[&<>]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];});}
  function highlight(text,q){
    var safe=esc(text);
    if(!q) return safe;
    try{ var re=new RegExp('('+q.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+')','ig'); return safe.replace(re,'<mark>$1</mark>'); }
    catch(e){ return safe; }
  }

  function boot(DATA){
    var reports=DATA.reports.filter(function(r){return r.day!=null;});
    reports.forEach(function(r){
      var b=r.body.slice();
      if(b.length && /^Day \d{1,4}( \(yesterday\))?$/i.test(b[0])) b.shift();
      r._body=b;
      r._search=(('day '+r.day+' '+r.date+' '+r.body.join(' ')).toLowerCase());
    });
    var days=reports.map(function(r){return r.day;});
    var minD=Math.min.apply(null,days), maxD=Math.max.apply(null,days);
    var minR=reports.find(function(r){return r.day===minD;});
    var maxR=reports.find(function(r){return r.day===maxD;});
    document.getElementById('s-count').textContent=reports.length;
    document.getElementById('s-span').textContent=fmtSpan(minR.date,maxR.date);

    var state={q:'',src:'all',sort:'new'};
    var logEl=document.getElementById('log');
    var countEl=document.getElementById('count');

    function render(){
      var q=state.q.trim().toLowerCase();
      var list=reports.filter(function(r){
        if(state.src!=='all' && r.source!==state.src) return false;
        if(q && r._search.indexOf(q)<0) return false;
        return true;
      });
      list.sort(function(a,b){return state.sort==='new'? b.day-a.day : a.day-b.day;});
      countEl.textContent=list.length+' / '+reports.length+' '+RTT('reports');
      if(!list.length){ logEl.innerHTML='<div class="empty">'+RTT('nomatch').replace('%s',esc(state.q))+'</div>'; return; }
      var html='';
      for(var i=0;i<list.length;i++){
        var r=list[i];
        if(i>0 && !q){
          var prev=list[i-1];
          var gap=Math.abs(r.day-prev.day)-1;
          if(gap>=14){ html+='<div class="gap"><span>'+RTT('gap').replace('%d',gap)+'</span></div>'; }
        }
        var bodyHtml='';
        for(var j=0;j<r._body.length;j++){
          var ln=r._body[j];
          var isHead=ln.length<=42 && /:$/.test(ln) && !/\d/.test(ln.replace(/:$/,'').slice(-3));
          bodyHtml += isHead
            ? '<div class="subhead">'+highlight(ln.replace(/:$/,''),q)+'</div>'
            : '<div class="line">'+highlight(ln,q)+'</div>';
        }
        var srcName=r.source.charAt(0).toUpperCase()+r.source.slice(1);
        html +=
          '<article class="entry" id="day-'+r.day+'">'+
            '<span class="node"></span>'+
            '<div class="stamp"><span class="day">'+RTT('day').replace('%d',r.day)+'</span><span class="date">'+fmtDate(r.date)+'</span></div>'+
            '<div class="card">'+
              '<div class="src '+r.source+'"><span class="dot"></span>'+srcName+'</div>'+
              '<div class="body">'+bodyHtml+'</div>'+
              '<div class="card-foot">'+
                '<a class="footage" href="/index.html?from='+shiftISO(r.date,-1)+'&to='+shiftISO(r.date,1)+'">'+
                  RTT('footage')+' <span class="arw">→</span></a>'+
              '</div>'+
            '</div>'+
          '</article>';
      }
      logEl.innerHTML=html;
      applyHash();
    }

    // DEEP LINK TO ONE DAY:  /reports.html#day-126
    // The node map records, for 56,972 of its events, the daily report that covers the same
    // date -- but it had nowhere to send a reader, because no report carried an id and the
    // page ignored the URL hash. With 516 reports sorted newest-first, "Day 126" meant
    // scrolling or searching. Now the map can link straight to the entry.
    var hashDone=false;
    function applyHash(){
      var m=(location.hash||'').match(/^#day-(\d{1,4})$/i);
      if(!m || hashDone) return;
      var el=document.getElementById('day-'+m[1]);
      if(!el){
        // Filtered out by a search or a source filter? Drop the filter and try once more --
        // a link that lands on "no results" looks like the report does not exist.
        if(state.q || state.src!=='all'){
          state.q=''; state.src='all';
          var qq=document.getElementById('q'); if(qq) qq.value='';
          render();                       // re-entry is safe: hashDone guards the scroll
        }
        return;
      }
      hashDone=true;
      el.scrollIntoView({block:'center'});
      // Say which one the link meant. Set directly rather than via a class: this page carries
      // its own styles in 26 separate HTML files, and one script edit should not need 26.
      var card=el.querySelector('.card')||el;
      card.style.transition='box-shadow .45s ease';
      card.style.boxShadow='0 0 0 2px #e0463b';
      setTimeout(function(){ card.style.boxShadow=''; }, 3000);
    }
    window.addEventListener('hashchange',function(){ hashDone=false; applyHash(); });

    var qi=document.getElementById('q'); var t;
    qi.addEventListener('input',function(){clearTimeout(t);t=setTimeout(function(){state.q=qi.value;render();},120);});
    document.querySelectorAll('.seg [data-sort]').forEach(function(btn){
      btn.addEventListener('click',function(){
        state.sort=btn.getAttribute('data-sort');
        document.querySelectorAll('.seg [data-sort]').forEach(function(b){b.setAttribute('aria-pressed',b===btn);});
        render();
      });
    });
    render();
  }

  if(LANG==='en'){ boot(inline); }
  else {
    fetch('/reports_'+LANG+'.json').then(function(r){return r.ok?r.json():Promise.reject();})
      .then(function(d){ boot(d && d.reports && d.reports.length ? d : inline); })
      .catch(function(){ boot(inline); });
  }
})();
