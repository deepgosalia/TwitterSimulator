defmodule User do
  use GenServer
  def start_link(usr_info) do
    {:ok,usr_process_id} = GenServer.start_link(__MODULE__, usr_info)
    usr_id = Enum.at(usr_info, 0)
    usr_pswd = Enum.at(usr_info, 1)
    live = Enum.at(usr_info, 2)
    message_queue = Enum.at(usr_info,3)
    :ets.insert(:usrProcessTable,{usr_id, [usr_pswd,live,message_queue,usr_process_id]})
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
    #generate time stamp
    time_stamp = :os.system_time()

    # add that <TimeStamp, Message> to msgTable
    :ets.insert(:msgTable,{time_stamp,[message,uid]})
    # send it to the engine
    GenServer.cast(pid, {:sendMsg,uid,time_stamp})
  end

  def receive_message(from,to,message_id) do
    sub = User.getPID(to)
    # add message to its list
    User.addMessage(message_id,sub);
    GenServer.cast(sub,{:rec_msg,from,to,message_id})
  end

  def getPID(uid) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,3)
    pid
  end

  def addMessage(message_id,pid) do
    GenServer.cast(pid, {:addMsg,message_id})
  end

  def handle_cast({:addMsg,message_id},state) do
    #get list
    list = Enum.at(state,3)
    # append new message id
    list = list ++ [message_id]
    {:noreply, [Enum.at(state, 0),Enum.at(state, 1),Enum.at(state, 2),list,Enum.at(state, 4)]}
  end

  def handle_cast({:rec_msg,from,to,message_id},state) do
    #:ets.insert(:msgTable,{time_stamp,message})
    [{_,[message,from]}] = :ets.lookup(:msgTable, message_id)
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
