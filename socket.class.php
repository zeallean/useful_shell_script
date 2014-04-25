<?php
/**
 * Socket协议类
 */
class SockConnControlCenter {

	var $ParmSetConnectTimeOut =1; // connection timeout
	var $ParmSetStreamTimeOut = 1;  // the socket stream timeout

	function SendCmd($str,$ip, $port)
	{
		$comm = $str;
		$errorMsg = null;		
		$rs = $this->_SocketCommunication($comm, $ip, $port, $this->ParmSetConnectTimeOut, $this->ParmSetStreamTimeOut, 1, $errorMsg);
		if ($rs == '')
		{//获取内容为空，超时了
		    return '-2';
		}
		if ($rs === false || $errorMsg !== null) {
			echo "errorMsg is ".$errorMsg."<br>";
			$this->_ErrorLog('rs type='.gettype($rs).' error msg type='.gettype($errorMsg).' error msg='.$errorMsg);
			return false;
		}
		return $rs;
	}
	function _ErrorLog($str){
		error_log($str,3,getcwd()."/errlog.txt");
	}
	//socket setting//////////////////////////////////////////////////////////////////////////////////
	/**
	 * 统一socket处理函数，其中_ErrorLog为一个伪调用，各个接口可以用自己的内部的日志函数进行替换
	 * @param string $comm 请求字符串
	 * @param string $host 连接服务器ip
	 * @param int $port 对应服务器的端口
	 * @param float $ctime 链接超时；此参数为浮点数，如1, 1.0, 1.2均可
	 * @param float $ptime 读写超时；格式和$ctime相同
	 * @param int $protocol socket是几字节的协议；表示前N个字节为返回字符串的长度，当前用的是4字节和6字节
	 * @param string $errorMsg 错误描述
	 * @return 成功返回服务端的返回数据；失败返回false，参数$errorMsg指出当前的错误描述
	 */
	function _SocketCommunication($comm, $host, $port, $ctime, $ptime, $protocol, &$errorMsg) {
		$sock = $this->_SocketConnect($host, $port, $ctime, $ptime, $errorMsg);
		if ($sock === false) {
			return false;
		}
		$result = $this->_SocketWrite($sock, $host, $port, $comm, $errorMsg);
		if ($result === false) {
			socket_close($sock);
			return false;
		}
		$response = $this->_SocketRead($sock, $host, $port, $protocol, $errorMsg);
		if ($response === false) {
			socket_close($sock);
			return false;
		}
		socket_close($sock);
		return $response;
	}
	
	function _SocketConnect($host, $port, $ctime, $ptime, &$errorMsg) {
		$sock = @socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
	    if(!$sock) {
	        $errorMsg = "Failed to create socket: $host : $port " . socket_strerror(socket_last_error($sock));
	        return false;
	    }
	    socket_set_nonblock($sock);
	    @socket_connect($sock, $host, $port);
	    socket_set_block($sock);
	    $fd_read = array($sock);
	    $fd_write = array($sock);
	    $except = null;
	    $ret = @socket_select($fd_read, $fd_write, $except, floor($ctime), fmod($ctime, 1) * 1000000);
	    if($ret != 1) {
	        if ($ret == 0) {
	        	$errorMsg = "Connection timeout: $host : $port " . socket_strerror(socket_last_error($sock));
	        } elseif ($ret == 2) {
	        	$errorMsg = "Connection refused: $host : $port " . socket_strerror(socket_last_error($sock));
	        } else {
	        	$errorMsg = socket_strerror(socket_last_error($sock)) . ": $host : $port";
	        }
			socket_close($sock);
	        return false;
	    }
		// 分别设置读写超时
	    socket_set_option($sock, SOL_SOCKET, SO_SNDTIMEO, array("sec" =>floor($ptime), "usec" => fmod($ptime, 1) * 1000000));
	    socket_set_option($sock, SOL_SOCKET, SO_RCVTIMEO, array("sec" =>floor($ptime), "usec" => fmod($ptime, 1) * 1000000));
		//echo "sock ===>$sock\n";
		return $sock;
	}
	
	function _SocketWrite($sock, $host, $port, $comm, &$errorMsg) {
	    // socket写，最多循环20次写
	    $writtenLen = 0; // 已经写的长度
	    $counter = 0; // 循环写的次数
	    $content = $comm;
	    do {
		    $written = @socket_write($sock, $content, strlen($content));
		    if (false === $written) {
		        $errorMsg = "Failed to write data on the socket: $host : $port " . socket_strerror(socket_last_error($sock));
		        return false;
		    }
		    $writtenLen += $written;
		    $counter++;
		    if ($counter > 20) {
	        	$errorMsg = "Exceed 20 time while writing data on socket: $host : $port " . socket_strerror(socket_last_error($sock));
		    	return false;
		    }
		    if ($written < strlen($comm)) {
		    	$content = substr($comm, $writtenLen);
		    }
	    } while ($writtenLen < strlen($comm));
	    
	    return true;
	}
	
	function _SocketRead($sock, $host, $port, $protocol, &$errorMsg) {		
		//读取返回内容的长度
		$result = '';
	   @socket_recv($sock, $result, 20000, MSG_WAITALL);
		return $result;
	}
}