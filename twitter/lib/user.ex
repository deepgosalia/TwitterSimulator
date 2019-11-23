defmodule User do
  use GenServer
  def start_link(usr_info) do
    {:ok,usr_process_id} = GenServer.start_link(__MODULE__, usr_info)
    usr_id = Enum.at(usr_info, 0)
    usr_pswd = Enum.at(usr_info, 1)
    live = Enum.at(usr_info, 2)
    :ets.insert(:usrProcessTable,{usr_id, [usr_pswd,live,usr_process_id]})
  end

  def init(usr_info) do
    Process.flag(:trap_exit, true)
    {:ok,usr_info}
  end

  def isOnline(pid) do
    status = GenServer.call(pid, :getUserStatus)
    status
  end

  def send_message(uid, message) do
    pid = User.getPID(uid)
    GenServer.cast(pid, {:sendMsg,uid,message})
  end

  def receive_message(from,to,message) do
    sub = User.getPID(to)
    GenServer.cast(sub,{:rec_msg,from,to,message})
  end

  def getPID(uid) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,2)
    pid
  end

  def handle_cast({:rec_msg,from,to,message},state) do
    IO.puts("User#{to}: #{message} from #{from}")
    {:noreply,state}
  end

  def handle_cast({:sendMsg,uid,msg},state) do
    Engine.distributeMsg(uid,msg);
    {:noreply,state}
  end

  def handle_call(:getUserStatus,_from, usr_info) do
    {:reply,Enum.at(usr_info,2),usr_info}
  end
end
