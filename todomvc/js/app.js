// Generated by CoffeeScript 1.7.1
(function() {
  "use strict";
  var EventController, Renderer, TodoList, Todos, UrlController, routes,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Todos = [];

  Todos.find_by_id = function(id) {
    var t, _i, _len;
    for (_i = 0, _len = this.length; _i < _len; _i++) {
      t = this[_i];
      if (t.get("id") === id) {
        return t;
      }
    }
  };

  TodoList = (function(_super) {
    __extends(TodoList, _super);

    function TodoList() {
      return TodoList.__super__.constructor.apply(this, arguments);
    }

    TodoList.attrs = [
      "title", {
        completed: false
      }, "id"
    ];

    TodoList.form_name = "#new-todo";

    TodoList.guid_for = "id";

    TodoList.prototype.is_active = function() {
      return !this.get("completed");
    };

    TodoList.prototype.is_completed = function() {
      return this.get("completed");
    };

    return TodoList;

  })(Sirius.BaseModel);

  Renderer = {
    template: new EJS({
      url: 'js/todos.ejs'
    }),
    render: function(data) {
      var klass, t, template, todos;
      if (data == null) {
        data = [];
      }
      todos = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          t = data[_i];
          klass = t.get("completed") ? "completed" : "";
          _results.push({
            "class_name": klass,
            "title": t.get("title"),
            id: t.get("id")
          });
        }
        return _results;
      })();
      template = this.template.render({
        todos: todos
      });
      return $("#todo-list").html("").html(template);
    }
  };

  UrlController = {
    root: function() {
      return Renderer.render(Todos);
    },
    active: function() {
      var t, todos;
      todos = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = Todos.length; _i < _len; _i++) {
          t = Todos[_i];
          if (t.is_active()) {
            _results.push(t);
          }
        }
        return _results;
      })();
      return Renderer.render(todos);
    },
    completed: function() {
      var t, todos;
      todos = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = Todos.length; _i < _len; _i++) {
          t = Todos[_i];
          if (t.is_completed()) {
            _results.push(t);
          }
        }
        return _results;
      })();
      return Renderer.render(todos);
    }
  };

  EventController = {
    start: function() {
      Todos.push(new TodoList({
        title: "Create a TodoMVC template",
        completed: true
      }));
      Todos.push(new TodoList({
        title: "Rule the web"
      }));
      return Renderer.render(Todos);
    },
    destroy: function(event, id) {
      var i, index, t, todo, _i, _len;
      todo = Todos.find_by_id(id);
      index = null;
      for (i = _i = 0, _len = Todos.length; _i < _len; i = ++_i) {
        t = Todos[i];
        if (t.get("id") === id) {
          index = i;
        }
      }
      if (index !== null) {
        Todos.splice(index, 1);
        return $(event.target).parents("li").remove();
      }
    },
    mark: function(event, id) {
      var todo;
      todo = Todos.find_by_id(id);
      if (todo.get("completed")) {
        todo.set("completed", false);
      } else {
        todo.set("completed", true);
      }
      return $(event.target).parents("li").toggleClass("completed");
    },
    mark_all: function(event, klass) {
      var t, _i, _j, _len, _len1;
      if (klass === "marked") {
        for (_i = 0, _len = Todos.length; _i < _len; _i++) {
          t = Todos[_i];
          t.set("completed", true);
        }
      } else {
        for (_j = 0, _len1 = Todos.length; _j < _len1; _j++) {
          t = Todos[_j];
          t.set("completed", false);
        }
      }
      $(event.target).toggleClass("marked");
      return Renderer.render(Todos);
    },
    is_enter: function(event) {
      if (event.which === 13) {
        return true;
      }
      return false;
    },
    new_todo: function(event) {
      var new_todo;
      new_todo = TodoList.from_html();
      console.log(new_todo);
      Todos.push(new_todo);
      Renderer.render(Todos);
      return $("#new-todo").val('');
    },
    update_footer: function() {
      var active, completed, _;
      if (Todos.length === 0) {
        $("#footer").hide();
        return;
      } else {
        $("#footer").show();
      }
      active = ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = Todos.length; _i < _len; _i++) {
          _ = Todos[_i];
          if (_.is_active()) {
            _results.push(_);
          }
        }
        return _results;
      })()).length;
      completed = ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = Todos.length; _i < _len; _i++) {
          _ = Todos[_i];
          if (_.is_completed()) {
            _results.push(_);
          }
        }
        return _results;
      })()).length;
      $("#todo-count strong").text(active);
      if (completed > 0) {
        $("#clear-completed").show();
        return $("#clear-completed").text("Clear completed (" + completed + ")");
      } else {
        return $("#clear-completed").hide();
      }
    },
    edit: function(e) {
      $(e.target).parents("li").addClass("editing");
      return $(e.target).children(".edit").focus();
    },
    update: function(e, id) {
      var todo, trg;
      trg = $(e.target);
      todo = Todos.find_by_id(id);
      todo.set("title", trg.val());
      trg.val('');
      trg.parents("li").toggleClass("editing");
      return Renderer.render(Todos);
    },
    clear: function(e) {
      var i, t, xs, _i, _len;
      xs = (function() {
        var _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = Todos.length; _i < _len; i = ++_i) {
          t = Todos[i];
          if (t.is_completed()) {
            _results.push(i);
          }
        }
        return _results;
      })();
      for (_i = 0, _len = xs.length; _i < _len; _i++) {
        i = xs[_i];
        Todos.splice(i, 1);
      }
      return Renderer.render(Todos);
    }
  };

  routes = {
    "#": {
      controller: UrlController,
      action: "root"
    },
    "#/active": {
      controller: UrlController,
      action: "active"
    },
    "#/completed": {
      controller: UrlController,
      action: "completed"
    },
    "application:run": {
      controller: EventController,
      action: "start"
    },
    "click button.destroy": {
      controller: EventController,
      action: "destroy",
      after: "update_footer",
      data: "data-id"
    },
    "click li input.toggle": {
      controller: EventController,
      action: "mark",
      after: "update_footer",
      data: "data-id"
    },
    "click #toggle-all": {
      controller: EventController,
      action: "mark_all",
      after: "update_footer",
      data: "class"
    },
    "keypress #new-todo": {
      controller: EventController,
      action: "new_todo",
      guard: "is_enter",
      after: "update_footer"
    },
    "dblclick li": {
      controller: EventController,
      action: "edit"
    },
    "keypress input.edit": {
      controller: EventController,
      action: "update",
      data: "data-id",
      guard: "is_enter"
    },
    "click #clear-completed": {
      controller: EventController,
      action: "clear",
      after: "update_footer"
    }
  };

  $(function() {
    var app;
    return app = Sirius.Application.run({
      route: routes,
      adapter: new JQueryAdapter(),
      start: "#"
    });
  });

}).call(this);
