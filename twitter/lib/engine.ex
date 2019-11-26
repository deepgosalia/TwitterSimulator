defmodule Engine do
  use GenServer
  def start_link(arg) do
    {:ok,eng_id} = GenServer.start_link(__MODULE__, arg)

  end

  def init(arg) do
    Process.flag(:trap_exit, true)
    {:ok,arg}
  end

  def getPID(uid) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,2)
    pid
  end

  def distributeMsg(uid, msg_id) do
    # for each subscriber existing send them tweet, if not online then save it else send it
    [{_,eid}] = :ets.lookup(:eid, "eid")
    GenServer.cast(eid,{:distMsg,uid,msg_id})
    # get subscriber list for user

  end

  def queryForSub(usr, sub) do
    [{_,subList}] = :ets.lookup(:subTable, usr)
    # first we need to confirm if user is subscribed to that user
    if(Enum.member?(subList, sub)) do
      [{_,data}] = :ets.lookup(:usrProcessTable, usr)
      pid = Enum.at(data,2)
      #subPID = Engine.getPID(sub)
      GenServer.cast(pid, {:getSubMsg,sub})
    end

  end

  def handle_cast({:distMsg,uid,message_id},state) do
    [{_,subList}] = :ets.lookup(:subTable, uid)

    Enum.each(subList, fn(sub)->
      #sub_pid = User.getPID(sub)
      User.receive_message(uid,sub,message_id)
    end)
    {:noreply,state}
  end

end

