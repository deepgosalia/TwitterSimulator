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

  def login() do

  end

  def logout()do
    
  end

  def isOnline(pid) do
    status = GenServer.call(pid, :getUserStatus)
    status
  end

  def send_message(uid, message) do
    pid = User.getPID(uid)
    #generate time stamp
    time_stamp = :os.system_time()
    time_stamp = time_stamp + uid
    :ets.insert(:msgTable,{time_stamp,[message,uid]})
    User.addMessageSend(time_stamp,pid)
    # send it to the engine
    GenServer.cast(pid, {:sendMsg,uid,time_stamp})
  end

  def receive_message(from,to,message_id) do
    sub = User.getPID(to)
    # add message to its list
    User.addMessageRec(message_id,sub);
    GenServer.cast(sub,{:rec_msg,from,to,message_id})
  end

  def getPID(uid) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,2)
    pid
  end

  def addMessageRec(message_id,pid) do
    GenServer.cast(pid, {:addMsgRec,message_id})
  end

  def getListRec(pid) do
    {:ok,list}=GenServer.call(pid,{:getListRec})
    list
  end

  def addMessageSend(message_id,pid) do
    GenServer.cast(pid, {:addMsgSend,message_id})
  end

  def getListSend(pid) do
    {:ok,list}=GenServer.call(pid,{:getListSend})
    list
  end

  def handle_cast({:addMsgSend,message_id},state) do
    #get list
    list = Enum.at(state,4)
    # append new message id
    list = list ++ [message_id]
    {:noreply, [Enum.at(state, 0),Enum.at(state, 1),Enum.at(state, 2),Enum.at(state, 3),list]}
  end

  def handle_cast({:addMsgRec,message_id},state) do
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

  def handle_cast({:getSubMsg,sub},state) do

    [{_,data}] = :ets.lookup(:usrProcessTable, sub)
    subPID = Enum.at(data,2)
    # get entire msg list of that user
    list = Enum.at(state, 3)
    IO.inspect(list)
    # for each message search in table
    IO.puts("Here are your result")
    Enum.each(list, fn (message_id) ->
      [{_,[message,from]}] = :ets.lookup(:msgTable, message_id)
      if from == sub do
        IO.puts("Tweet: #{message} from #{from}")
      end
    end)
    {:noreply,state}
  end

  def handle_call(:getUserStatus,_from, usr_info) do
    {:reply,Enum.at(usr_info,2),usr_info}
  end

  def handle_call({:getListRec},_from,state) do
    {:reply, Enum.at(state, 3),state}
  end

  def handle_call({:getListSend},_from,state) do
    {:reply, Enum.at(state, 4),state}
  end

end
