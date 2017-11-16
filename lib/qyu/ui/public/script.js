(function(){
  var collapser = function(){
    var elem = this;
    if ( elem.classList.contains('open') ){
      var root = elem.dataset.root;
      var level = elem.dataset.level;
      document.querySelectorAll('tr[data-root="' + root + '"]').forEach(function(el){
        var currentLevel = parseInt(el.dataset.level);
        if (currentLevel > level) {
          el.classList.add('collapse');
          var parent = el.dataset.parent;
          document.querySelector('a[data-id="' + parent + '"]').classList.remove('open');
        }
      });
      elem.classList.remove('open');
    } else {
      var id = elem.dataset.id;
      document.querySelectorAll('[data-parent="' + id + '"]').forEach(function(el){
        el.classList.remove('collapse');
      });
      elem.classList.add('open');
    }
  }

  document.querySelectorAll('.collapser').forEach(function(elem){
    elem.addEventListener('click', collapser);
  });
}).call(this);
