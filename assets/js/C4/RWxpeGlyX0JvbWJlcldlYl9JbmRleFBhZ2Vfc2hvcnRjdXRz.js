/*
This file was generated automatically by the C4 compiler.
*/

const push = function(atom, module = "Elixir_BomberWeb_IndexPage", id, payload) {
  liveSocket.getSocket().channels[0].push("port["+module+"]["+id+"]["+atom+"]", payload)
}
const push_self = function(atom, id, payload) {
  liveSocket.getSocket().channels[0].push("port[Elixir_BomberWeb_IndexPage]["+id+"]["+atom+"]", payload)
}
const push_self_view = function(atom, payload) {
  liveSocket.getSocket().channels[0].push("port[Elixir_BomberWeb_IndexPage][undefined]["+atom+"]", payload)
}
const push_view = function(atom, module = "Elixir_BomberWeb_IndexPage", payload) {
  liveSocket.getSocket().channels[0].push("port["+module+"][undefined]["+atom+"]", payload)
}


export default function(e){
 const params = e.detail;
  hotkeys('right,left,up,down', function (event, handler){
    switch (handler.key) {
      case 'left':
        push_self_view("cmd_left", {});
        break;
      case 'right':
        push_self_view("cmd_right", {});
        break;
      case 'up':
        push_self_view("cmd_up", {});
        break;
      case 'down':
        push_self_view("cmd_down", {});
        break;
    }
  });
}