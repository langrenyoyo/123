<?php

namespace app\index\controller;

use think\Cache;
use think\Controller;
use think\Cookie;
use think\Db;
use think\Lang;
use think\Request;
use think\Log;

class Index extends Controller
{
    //maibao主页
    public function index()
    {

        $user=Request::instance()->param('u_id');
        $order = Db::table('mb_lunbo')->select();
        if($user){

            $user_arr=Db::table('mb_user')->where('u_id',$user)->field('u_id,user,u_img,tel,assets,balance,vip_static,trade_address')->find();

            if($user_arr['trade_address'] == '0' || $user_arr['trade_address'] == NULL || empty($user_arr['trade_address'])){
                $address = $this->getaddress($arr);
                Db::table('mb_user')->where('u_id',$user_arr['u_id'])->update(['trade_address' => $address]);
            }

            if(empty($user_arr['u_img'])){
                $user_arr['u_img'] = 'https://aaa.52qjwz.com/wangpay888.com/mubei/images/logo.png';
            }else{
                $user_arr['u_img'] = 'https://aaa.52qjwz.com/wangpay888.com/new_vpay_api/public/static/uploads/'.$user_arr['u_img'];
            }
//            var_dump($user_arr1);exit;
            $beijin=Db::table('mb_beijin')->where('bj_id',1)->value('bj_img');
            $data= array();
            $time =date('Y-m-d', time());
            $time1 = date("Y-m-d",strtotime("-1 day"));
            $data_start1= strtotime($time1.'00:00:00');
            $data_end1= strtotime($time1.'23:59:59');
            $date_start = strtotime($time.'00:00:00');
            $date_end = strtotime($time.'23:59:59');
            
            $asstes = Db::table('mb_balance_order')->where('type',5)
                ->where('u_id',$user)->where('bo_time','<=',$data_end1)
                ->where('bo_time','>=',$data_start1)->sum('bo_money');
            //  print_r($asstes);exit;
            $ass = Db::table('mb_balance_order')->where('type',1)
                ->where('u_id',$user)->where('bo_time','<=',$data_end1)
                ->where('bo_time','>=',$data_start1)->limit(1)->sum('bo_money');

            //type=18为购买商品付款后返回的加速释放积分标识
            $today_ass = Db::table('mb_balance_order')->where('type',18)
                ->where('u_id',$user)->where('bo_time','<=',$data_end1)
                ->where('bo_time','>=',$data_start1)->limit(1)->sum('bo_money');

            $today=Db::table('mb_today_assets')->where('u_id',$user)
                ->where('time','<=',$date_end)->where('time','>=',$date_start)->find();
            $time=Db::table('mb_config')->where('co_id',6)->find();
            $hou=date("G",$time['co_config']);
            $hour=date("G");
            $tan = 2;



            // exit;
            if(($asstes + $ass + $today_ass) > 0){
                if($today){
                    $tan=2;
                }else if($hou <= $hour && $user_arr['assets'] > 0){
                    $tan=1;
                }
            }

            foreach($order as $k=>$v){
                $data['lb_img'][$k]=$v['lb_img'];
            }

            //公告
            $n_count1 = Db::table('mb_notice')->count();
            $notice = Db::table('mb_notice')->order('n_id desc')->find();
            $n_count2 = Db::table('mb_notice_record')->where('u_id',$user)->count();

            //个人信息
            $m_count1 = Db::table('mb_message')->where('u_id',$user)->count();
            
            $m_count2 = Db::table('mb_message_record')->where('u_id',$user)->count();

            // print_r("<pre>");
            // print_r($order);exit;
            if($user_arr){
                return jsonp(['code' => 1, 'msg' => 'succeed','notice'=>$notice,'n_count'=>($n_count1-$n_count2),'m_count'=>($m_count1-$m_count2),'data'=>$user_arr,'images'=>$data,'tan'=>$tan,'beijin'=>$beijin,'gold'=>round(($asstes + $ass+$today_ass),2)]);
            }else{
                return jsonp(['code' => 2, 'msg' => '参数错误']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }



    public function red_bao(){

        $user=Request::instance()->param('u_id');
        if(Cache::get('red_bao'.$user)){
            return jsonp(['code' => 2, 'msg' => '频率过快']);
        }else{
            Cache::set('red_bao'.$user,true,3);
            $user_arr=Db::table('mb_user')->where('u_id',$user)->field('u_id,user,u_img,tel,assets,balance,vip_static')->find();
            $time =date('Y-m-d', time());
            $time1 = date("Y-m-d",strtotime("-1 day"));
            $data_start1= strtotime($time1.'00:00:00');
            $data_end1= strtotime($time1.'23:59:59');
            $date_start = strtotime($time.'00:00:00');
            $date_end = strtotime($time.'23:59:59');
           $today=Db::table('mb_today_assets')->where('u_id',$user)
                ->where('time','<=',$date_end)->where('time','>=',$date_start)->find();
          if(!$today){
            $ass1 = Db::table('mb_balance_order')->where('type',5)
                ->where('u_id',$user)->where('bo_time','<=',$data_end1)
                ->where('bo_time','>=',$data_start1)->sum('bo_money');
            $ass = Db::table('mb_balance_order')->where('type',1)
                ->where('u_id',$user)->where('bo_time','<=',$data_end1)
                ->where('bo_time','>=',$data_start1)->limit(1)->sum('bo_money');
            $today_ass = Db::table('mb_balance_order')->where('type',18)
                  ->where('u_id',$user)->where('bo_time','<=',$data_end1)
                  ->where('bo_time','>=',$data_start1)->sum('bo_money');
            $asstes = $ass1+$ass+$today_ass;
            if($user_arr['assets'] > $asstes && $asstes > 0){
//                $res1 = Db::table('mb_user')->where('u_id',$user)->setDec('assets',$asstes);
                $res2 = Db::table('mb_user')->where('u_id',$user)->setInc('balance',$asstes);
                $insert2 = Db::table('mb_today_assets')->insert([
                    'u_id' => $user,
                    'assets' => $asstes,
                    'time' => time(),
                ]);
                if($res2){
//                if($res1 && $res2){
                    return jsonp(['code' => 1, 'msg' => '领取成功','money'=>$asstes]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '参数错误']);
                }

            }else if($user_arr['assets'] <= $asstes  && $asstes > 0){
//                $res1 = Db::table('mb_user')->where('u_id',$user)->setDec('assets',$user_arr['assets']);
                $res2 = Db::table('mb_user')->where('u_id',$user)->setInc('balance',$user_arr['assets']);
                $insert2 = Db::table('mb_today_assets')->insert([
                    'u_id' => $user,
                    'assets' => $asstes,
                    'time' => time(),
                ]);
                if($res2){
//                if($res1 && $res2){
                    return jsonp(['code' => 1, 'msg' => '领取成功','money'=>$asstes]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '参数错误']);
                }
            };
          }
        }

        
    }



    //公告
    public function notice(){
        $token = Request::instance()->param('token');
        if($token){
            if($token == 'notice'){
                $notice=Db::table('mb_notice')->order('time', 'desc')->field('n_id,n_title,n_text,time')->select();
                foreach($notice as $k=>$v){
                    $notice[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                    $notice[$k]['n_text']=mb_substr(strip_tags($v['n_text']),0,60);
                }
                if($notice){
                    return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$notice]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '暂无数据']);
                }
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }

    //个人信息
    public function message(){
        $user = Request::instance()->param('u_id');
        if($user){
            $message=Db::table('mb_message')->where('u_id',$user)->order('m_time','desc')->field('m_id,m_title,m_text,m_time')->select();
            foreach($message as $k=>$v){
                $message[$k]['m_time']=date('Y-m-d H:i:s',$v['m_time']);
                $message[$k]['m_text']=mb_substr(strip_tags($v['m_text']),0,60);
            }
            if($message){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$message]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }


    //公告详情页
    public function notice_list(){
        $user = Request::instance()->param('token');
        $soid = Request::instance()->param('n_id');
        if($user == 'notice'){
            $card = Db::table('mb_notice')->where('n_id',$soid)->find();

//            foreach($card as $k=>$v){

//            }
            if($card){
                $card['time']=date('Y-m-d H:i:s',$card['time']);
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$card]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }


    //消息详情页
    public function message_list(){
        $user = Request::instance()->param('token');
        $soid = Request::instance()->param('m_id');
        if($user == 'message'){
            $card = Db::table('mb_message')->where('m_id',$soid)->find();

//            foreach($card as $k=>$v){

//            }
            if($card){

                $card['m_time']=date('Y-m-d H:i:s',$card['m_time']);
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$card]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }


    //关于(中文)
    public function about(){
        $token = Request::instance()->param('token');
        $type = Request::instance()->param('type');
        if($token){
            if($token == 'about'){
                $about=Db::table('mb_about')->where('type',$type)->field('a_text')->find();
                if($about){
                    return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$about]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '暂无数据']);
                }
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }

    public function lange(){
        
        $token = Request::instance()->param('token');
        if($token == 'lange'){
            return jsonp(['code' => 1, 'msg' => '参数错误！']);
        }
    }
    //关于(英文)
    public function about_t(){
        $token = Request::instance()->param('token');

        if($token){
            if($token == 'about_t'){
                $about=Db::table('mb_about')->where('type',2)->field('a_text')->find();
                if($about){
                    return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$about]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '暂无数据']);
                }
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }


    //cardUSDT页
    public function card(){
        $user = Request::instance()->param('u_id');
        if($user){
            $card = Db::table('mb_bank')->where('u_id',$user)->select();

            if($card){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$card]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }

    //资讯
    public function news(){
        $user = Request::instance()->param('token');
        if($user == 'news'){
            $card = Db::table('vpay_shop')->order('time desc')->select();

            foreach($card as $k=>$v){
                $card[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $card[$k]['sh_text']=mb_substr(strip_tags($v['sh_text']),0,60);
            }
            if($card){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$card]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }

    //资讯详情页
    public function news_list(){
        $user = Request::instance()->param('token');
        $soid = Request::instance()->param('so_id');
        if($user == 'news'){
            $card = Db::table('vpay_shop')->where('sh_id',$soid)->find();

//            foreach($card as $k=>$v){
                $card['time']=date('Y-m-d H:i:s',$card['time']);
//            }
            if($card){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$card]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }

    //分享
    public function share(){

        $user =Request::instance()->param('u_id');
        $arr=array(
            'uid'=>$user,
            'url'=>"http://".$_SERVER['HTTP_HOST']."/wangpay888.com/mubei/login/register.html?account=".$user

        );
        $url2=json_encode($arr);
        //$url2="http://".$_SERVER['HTTP_HOST']."/wangpay888.com/mubei/login/register.html?account=".$user;
        $url2 = base64_encode($url2);
        if($user){
            return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$arr,'url'=>"http://wangpay888.com/new_vpay_api/public/index/index/qrcode/text/$url2.html"]);
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }
    //银行
    public function bank(){
        $token = Request::instance()->param('token');
        if($token){
            if($token == 'bank'){
                $card = Db::table('mb_bank_name')
                    ->field('bn_id,bn_name')
                    ->select();
                if($card){
                    return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$card]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '暂无数据']);
                }
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }



    }

    //分享记录
    public function share_order(){
        $user = Request::instance()->param('u_id');
        $data = Db::table('mb_user')->where('f_uid',$user)->select();
        if($data){
            foreach($data as $k => $v){
                if(empty($v['u_img'])){
                    $data[$k]['u_img'] = '/wangpay888.com/mubei/images/logo.png';
                }
            }
            return json(['code' => 1, 'msg' => 'succeed','data'=>$data]);
        }else{
            return json(['code' => 2, 'msg' => '暂无数据']);
        }
//        var_dump($user);exit;
        /*if(!empty($user)){
            $order = Db::table('vpay_share_order')
                ->alias('a')
                ->join('mb_user w','a.user = w.u_id')
                ->where('a.u_id',$user)
                ->field('w.user,w.u_img,w.u_id,a.time,w.vip_static,w.tel')
                ->select();

            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }*/

    }


    public function qrcode($text) {
        \think\Loader::import('qrcode.qrcode');
        $text = base64_decode($text);
        return \QRcode::png($text);
        exit;
    }


    //买入数据接口
    public function purchase(){
        $user =  Request::instance()->param('u_id');
        if($user){
            $user_arr=Db::table('mb_user')->where('u_id',$user)->find();
            if($user_arr['is_card'] != 0){
                $card = Db::table('mb_bank')
                    ->alias('a')
//                    ->join('mb_bank_name w','a.b_name = w.bn_id')
                    ->field('a.b_branch,a.c_name,a.b_name,a.b_card,a.defult,a.way')
                    ->where('u_id',$user)
                    ->where('defult',1)
                    ->find();

                $order=Db::table('mb_sell_order')->where('type',1)->where('u_id',$user)->where('static',4)->count('s_id');
                $order1=Db::table('mb_sell_order')->where('type',2)->where('user',$user)->where('static','=',4)->count('s_id');
//                $order1=Db::table('mb_sell_order')->where('type',2)->where('user',$user)->where('static','>=',2)->count('s_id');

                $order3=Db::table('mb_sell_order')->where('type',1)->where('u_id',$user)->where('static',2)->count('s_id');
                $order4=Db::table('mb_sell_order')->where('type',2)->where('user',$user)->where('static',2)->count('s_id');

                $order6=Db::table('mb_sell_order')->where('type',1)->where('u_id',$user)->where('static',1)->where('user',null)->count('s_id');
                $order7=Db::table('mb_sell_order')->where('type',1)->where('u_id',$user)->where('user','>',1)->where('static','>',1)->where('static','<',4)->count('s_id');

                $order5=Db::table('mb_sell_order')->where('type',2)->where('static',1)->count('s_id');

                $config = Db::table('mb_config')->where('co_id',31)->value('co_config');

                if($card){
                    return jsonp([
                        'code' => 1,
                        'msg' => 'succeed',
                        'data'=>$card,
                        'result_pay'=>$order3+$order4,
                        'buy_center'=>$order5,
                        'no_order'=>$order6+$order7,
                        'order_result'=>$order+$order1,
                        'config'=>$config
                    ]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '请设置默认USDT']);
                }

            }else{
                return jsonp(['code' => 2, 'msg' => '请添加USDT']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }

    //买入记录
    public function result_turn(){
        $user = Request::instance()->param('u_id');
        if($user){
            $user_arr=Db::table('mb_balance_order')->where('u_id',$user)->order('bo_time desc')->where('type',3)->field('bo_money,target_uid,bo_time')->select();
            foreach($user_arr as $k=>$v){
                $user_arr[$k]['bo_time']=date('Y-m-d H:i:s',$v['bo_time']);
            }
            if($user_arr){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$user_arr]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }

    //买入未完成订单（未选择收款人）
    public function no_order(){
        $user = Request::instance()->param('u_id');
        if($user){
            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')
                ->join('mb_bank c','w.u_id_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
                ->where('mb_sell_order.type',1)
                ->where('mb_sell_order.u_id',$user)
                ->where('mb_sell_order.user',null)
                ->field('a.u_img,a.user,a.tel,c.b_name,c.c_name,c.b_branch,w.money,c.way,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money,w.shi_rmb')
                ->order('mb_sell_order.time', 'desc')
                ->select();
            foreach($order as $k=>$v){
                switch ($v['static']) {
                    case 1:
                        $message = '挂买中';
                        break;
                    case 2:
                        $message = '交易中';
                        break;
                    case 3:
                        $message = '确认中';
                        break;
                    case 4:
                        $message = '已完成';
                        break;

                }

                $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }

                $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                $order[$k]['uid_wx_img']=$u_idWx['img'];
                $order[$k]['uid_ali_img']=$u_idAli['img'];

                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $order[$k]['static']=$message;
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }

        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }
    //买入未完成订单（已选择收款人）
    public function no_order_t(){
        $user = Request::instance()->param('u_id');
        if($user){

            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')
//
//                ->join('mb_bank c','w.u_id = c.u_id')

//                ->join('mb_bank_name n','c.b_name = n.bn_id')

                ->where('mb_sell_order.type','1,2')
                ->where('mb_sell_order.u_id',$user)
                ->whereOr('mb_sell_order.user',$user)
                ->where('mb_sell_order.static','>',1)
                ->where('mb_sell_order.static','<',4)
                ->field('a.u_img,a.tel,w.type,w.money,w.s_id,w.static,w.time,w.u_id,w.user,w.shi_money,w.shi_rmb,s_id,w.user_bank')
                ->order('mb_sell_order.time', 'desc')
                ->select();
//            var_dump($order);exit;
//            var_dump(Db::table('mb_user')->getLastSql());exit;
            $new_order = array();
            foreach($order as $k=>$v){
                if($v['static'] != 4){
                    switch ($v['static']) {
                        case 1:
                            $message = '挂买中';
                            break;
                        case 2:
                            $message = '交易中';
                            break;
                        case 3:
                            $message = '确认中';
                            break;
                        case 4:
                            $message = '已完成';
                            break;

                    }
                    $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                    if(!$v['shi_rmb']){
                        $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                    }

                    //添加银行卡信息
                    $u_idBank = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('defult',1)->find();
                    $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                    $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                    $userBank = Db::table('mb_bank')->where('u_id',$v['user'])->where('defult',1)->find();
                    $userWx = Db::table('mb_bank')->where('u_id',$v['user'])->where('way',2)->find();
                    $userAli = Db::table('mb_bank')->where('u_id',$v['user'])->where('way',3)->find();

                    $order[$k]['uid_c_name']=$u_idBank['c_name'];
                    $order[$k]['uid_b_name']=$u_idBank['b_name'];
                    $order[$k]['uid_b_card']=$u_idBank['b_card'];
                    $order[$k]['uid_b_branch']=$u_idBank['b_branch'];
                    $order[$k]['uid_wx_img']=$u_idWx['img'];
                    $order[$k]['uid_ali_img']=$u_idAli['img'];

                    $order[$k]['targetuid_c_name']=$userBank['c_name'];
                    $order[$k]['targetuid_b_name']=$userBank['b_name'];
                    $order[$k]['targetuid_b_card']=$userBank['b_card'];
                    $order[$k]['targetuid_b_branch']=$u_idBank['b_branch'];
                    $order[$k]['targetuid_wx_img']=$userWx['img'];
                    $order[$k]['targetuid_ali_img']=$userAli['img'];

                    
                    if($user == $v['user']){
                        $tel = Db::table('mb_user')->where('u_id',$v['u_id'])->value('tel');
                    }else{
                        $tel = Db::table('mb_user')->where('u_id',$v['user'])->value('tel');
                    }
                    $order[$k]['tel'] = $tel;
                    $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                    $order[$k]['static']=$message;
                    $new_order[] = $order[$k];
                }

            }
            if($new_order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$new_order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }

        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }

    //买入已完成订单
    public function result_order(){
        $user = Request::instance()->param('u_id');
        if($user){
//           Db::table('mb_sell_order')->where('type',1)->where('u_id',$user)->where('static',4)->order('time', 'desc')->select();
            $order=Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.user')
                ->where('mb_sell_order.type',1)
                ->where('mb_sell_order.u_id',$user)
                ->where('mb_sell_order.static',4)
                ->field('a.tel,w.money,w.s_id,w.static,w.time,w.u_id,w.user,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();
            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //买入操作订单
    public function result_order_t(){
        $user = Request::instance()->param('u_id');
        if($user){
//            $order=Db::table('mb_sell_order')->where('type',2)->where('user',$user)->where('static','>=',2)->order('time', 'desc')->select();
            $order=Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.user')
                ->where('mb_sell_order.type',2)
                ->where('mb_sell_order.user',$user)
                ->where('mb_sell_order.static','=',4)
//                ->where('mb_sell_order.static','>=',2)
                ->field('a.tel,w.money,w.s_id,w.static,w.time,w.u_id,w.user,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();

            foreach($order as $k=>$v){
                switch ($v['static']) {
                    case 1:
                        $message = '挂买中';
                        break;
                    case 2:
                        $message = '交易中';
                        break;
                    case 3:
                        $message = '确认中';
                        break;
                    case 4:
                        $message = '已完成';
                        break;

                }
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $order[$k]['static']=$message;
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //买入确认打款
    public function result_pay(){
        $user = Request::instance()->param('u_id');
        if($user){

            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')
                ->join('mb_bank c','w.u_id_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
                ->where("(w.type=2 and w.user=$user) OR (w.type=1 and w.u_id=$user)")
                ->where('w.static',2)
                ->field('a.u_img,w.type,a.user,a.tel,c.b_name,c.way,w.money,w.shi_rmb,w.s_id,w.static,w.time,
                w.u_id,c.b_card,c.c_name,w.shi_money,w.u_id,w.u_id_bank,w.user as target_uid,w.user_bank as target_bank')
                ->order('w.time', 'desc')
                ->select();
            // print_r(Db::table('mb_user')->getLastSql());exit;
            foreach($order as $k=>$v){
                $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }
                if($v['type'] ==1){
                    //target_uid
                    $bank = Db::table('mb_bank')->where('b_id',$v['target_bank'])->find();
                    $order[$k]['target_uid_c_name']=$bank['c_name'];
                    $order[$k]['target_uid_b_name']=$bank['b_name'];
                    $order[$k]['target_uid_b_card']=$bank['b_card'];
                    $order[$k]['target_uid_b_branch']=empty($bank['b_branch']) ? "" : $bank['b_branch'];

                    $u_idWx = Db::table('mb_bank')->where('u_id',$v['target_uid'])->where('way',2)->find();
                    $u_idAli = Db::table('mb_bank')->where('u_id',$v['target_uid'])->where('way',3)->find();
                    $order[$k]['target_uid_wx_img']=$u_idWx['img'];
                    $order[$k]['target_uidali_img']=$u_idAli['img'];

                    $target_user = Db::table('mb_user')->where('u_id',$v['target_uid'])->find();
                    $order[$k]['target_user']=$target_user['user'];
                    $order[$k]['target_tel']=$target_user['tel'];

                }elseif($v['type'] == 2){
                    $bank = Db::table('mb_bank')->where('b_id',$v['u_id_bank'])->find();
                    $order[$k]['target_uid_c_name']=$bank['c_name'];
                    $order[$k]['target_uid_b_name']=$bank['b_name'];
                    $order[$k]['target_uid_b_card']=$bank['b_card'];
                    $order[$k]['target_uid_b_branch']=empty($bank['b_branch']) ? "" : $bank['b_branch'];

                    $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                    $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                    $order[$k]['target_uid_wx_img']=$u_idWx['img'];
                    $order[$k]['target_uidali_img']=$u_idAli['img'];

                    $target_user = Db::table('mb_user')->where('u_id',$v['u_id'])->find();
                    $order[$k]['target_user']=$target_user['user'];
                    $order[$k]['target_tel']=$target_user['tel'];
                }

                if($user == $v['target_uid']){
                    $tel = Db::table('mb_user')->where('u_id',$v['u_id'])->value('tel');
                }else{
                    $tel = Db::table('mb_user')->where('u_id',$v['target_uid'])->value('tel');
                }
                $order[$k]['tel'] = $tel;
                
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //卖出确认打款
    public function result_pay_t(){
        $user = Request::instance()->param('u_id');
        if($user){
            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.user')
                ->join('mb_bank c','w.user_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
                ->where('mb_sell_order.type',1)
                ->where('mb_sell_order.u_id',$user)
                ->where('mb_sell_order.static',2)
                ->field('a.u_img,a.user,a.tel,c.b_name,w.money,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();

            foreach($order as $k=>$v){
                $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                $order[$k]['wx_img']=$u_idWx['img'];
                $order[$k]['ali_img']=$u_idAli['img'];
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $order[$k]['static']='待支付';
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //买入中心
    public function buy_sentic(){
        $money = Request::instance()->param('money');
        if($money){
            $config = Db::table('mb_config')->where('co_id',31)->value('co_config');
            $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');

            $order = Db::table('mb_sell_order')
                ->alias('w')
                ->join('mb_user a','w.u_id = a.u_id')
                ->join('mb_bank c','w.u_id_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')


                ->where('mb_sell_order.type',2)
                ->where('mb_sell_order.user',null)

                ->where('mb_sell_order.money',$money)
                ->field('a.u_img,a.user,a.tel,c.way,c.b_name,w.money,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money,w.shi_rmb,w.type')
                ->order('mb_sell_order.time', 'desc')
                ->select();
            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d',$v['time']);
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }
            }


            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order,'config'=>$config]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //卖出数据接口
    public function sell(){
        $user =  Request::instance()->param('u_id');
        if($user){
            $user_arr=Db::table('mb_user')->where('u_id',$user)->find();
            if($user_arr['is_card'] != 0){
                $card = Db::table('mb_bank')
                    ->where('u_id',$user)
                    ->where('defult',1)
                    ->find();

                $order=Db::table('mb_sell_order')->where('type',2)->where('u_id',$user)->where('static',4)->count('s_id');

                $order1=Db::table('mb_sell_order')->where('type',1)->where('user',$user)->where('static','=',4)->count('s_id');
//                $order1=Db::table('mb_sell_order')->where('type',1)->where('user',$user)->where('static','>=',2)->count('s_id');

                $order3=Db::table('mb_sell_order')->where('type',2)->where('u_id',$user)->where('static',3)->count('s_id');

                $order4=Db::table('mb_sell_order')->where('type',1)->where('user',$user)->where('static',3)->count('s_id');

                $order5=Db::table('mb_sell_order')->where('type',1)->where('static',1)->count('s_id');


                $order6=Db::table('mb_sell_order')->where('type',2)->where('u_id',$user)->where('static',1)->count('s_id');
                $order7=Db::table('mb_sell_order')->where('type',2)->where('u_id',$user)->where('user','>',0)->where('static','>',1)->where('static','<',4)->count('s_id');

                $config = Db::table('mb_config')->where('co_id',31)->value('co_config');
                if($card){
                    return jsonp([
                        'code' => 1,
                        'msg' => 'succeed',
                        'data'=>$card,
                        'result_pay'=>$order3+$order4,
                        'buy_center'=>$order5,
                        'no_order'=>$order6+$order7,
                        'order_result'=>$order+$order1,
                        'config'=>$config
                    ]);
                }else{
                    return jsonp(['code' => 2, 'msg' => '请设置默认USDT']);
                }

            }else{
                return jsonp(['code' => 2, 'msg' => '请添加USDT']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }
    //卖出记录
    public function result_out(){

        $user = Request::instance()->param('u_id');
        if($user){
            $user_arr=Db::table('mb_balance_order')->where('u_id',$user)->order('bo_time desc')->where('type',4)->field('bo_money,target_uid,bo_time')->select();
            foreach($user_arr as $k=>$v){
                $user_arr[$k]['bo_time']=date('Y-m-d H:i:s',$v['bo_time']);
            }
            if($user_arr){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$user_arr]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }

    }
    //卖出未完成订单（未选择付款人）
    public function no_order_a(){
        $user = Request::instance()->param('u_id');
        if($user){
            $order = Db::table('mb_user')
                ->alias('a')

                ->join('mb_sell_order w','a.u_id = w.u_id')

                ->join('mb_bank c','w.u_id_bank = c.b_id')

//                ->join('mb_bank_name n','c.b_name = n.bn_id')

                ->where('mb_sell_order.type',2)
                ->where('mb_sell_order.u_id',$user)
                ->where('mb_sell_order.user',null)
                ->field('a.u_img,a.user,a.tel,c.way,c.b_name,c.b_branch,w.money,w.shi_rmb,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();

            foreach($order as $k=>$v){
                switch ($v['static']) {
                    case 1:
                        $message = '挂卖中';
                        break;
                    case 2:
                        $message = '交易中';
                        break;
                    case 3:
                        $message = '确认中';
                        break;
                    case 4:
                        $message = '已完成';
                        break;

                }
                $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }

                $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                $order[$k]['uid_wx_img']=$u_idWx['img'];
                $order[$k]['uid_ali_img']=$u_idAli['img'];

                $order[$k]['static']=$message;
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);

            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据','user'=>$user]);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //卖出未完成订单（已选择付款人）
    public function no_order_c(){
        $user = Request::instance()->param('u_id');
        if($user){
            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.user')
//                ->join('mb_sell_order w','a.u_id = w.u_id')
//                ->join('mb_bank c','w.user = c.u_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
                ->where('mb_sell_order.type',2)
                ->where('mb_sell_order.u_id',$user)
                ->whereOr('mb_sell_order.user',$user)
                ->where('mb_sell_order.user','>',0)
                ->where('mb_sell_order.static','neq',4)
                ->field('a.u_img,w.user,a.tel,w.money,w.s_id,w.static,w.time,w.u_id,w.shi_money,w.shi_rmb,w.type')
                ->order('mb_sell_order.time', 'desc')
                ->select();
//var_dump($order);exit;
//            var_dump(Db::table('mb_user')->getLastSql());exit;
            $new_order = array();
            foreach($order as $k=>$v){
                if($v['static'] != 4){
                    switch ($v['static']) {
                        case 1:
                            $message = '挂卖中';
                            break;
                        case 2:
                            $message = '待付款';
                            break;
                        case 3:
                            $message = '确认收款';
                            break;
                        case 4:
                            $message = '已完成';
                            break;

                    }
                    $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                    if(!$v['shi_rmb']){
                        $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                    }

                    //添加银行卡信息
                    $u_idBank = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('defult',1)->find();
                    $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                    $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                    $userBank = Db::table('mb_bank')->where('u_id',$v['user'])->where('defult',1)->find();
                    $userWx = Db::table('mb_bank')->where('u_id',$v['user'])->where('way',2)->find();
                    $userAli = Db::table('mb_bank')->where('u_id',$v['user'])->where('way',3)->find();
                    $order[$k]['uid_c_name']=$u_idBank['c_name'];
                    $order[$k]['uid_b_name']=$u_idBank['b_name'];
                    $order[$k]['uid_b_card']=$u_idBank['b_card'];
                    $order[$k]['uid_b_branch']=empty($u_idBank['b_branch']) ? "" : $u_idBank['b_branch'];
                    $order[$k]['uid_wx_img']=$u_idWx['img'];
                    $order[$k]['uid_ali_img']=$u_idAli['img'];
                    $order[$k]['uid_way']=$u_idBank['way'];

                    $order[$k]['targetuid_c_name']=$userBank['c_name'];
                    $order[$k]['targetuid_b_name']=$userBank['b_name'];
                    $order[$k]['targetuid_b_card']=$userBank['b_card'];
                    $order[$k]['targetuid_b_branch']=empty($userBank['b_branch']) ? "" : $userBank['b_branch'];
                    $order[$k]['targetuid_wx_img']=$userWx['img'];
                    $order[$k]['targetuid_ali_img']=$userAli['img'];
                    $order[$k]['targetuid_way']=$userBank['way'];
                    
                    // if($v['type'] ==1){
                    //     //user
                    //     $tel = Db::table('mb_user')->where('u_id',$v['u_id'])->value('tel');
                    // }else{
                    //     //u_id
                        
                       
                    // }
                    if($user == $v['user']){
                        $tel = Db::table('mb_user')->where('u_id',$v['u_id'])->value('tel');
                    }else{
                        $tel = Db::table('mb_user')->where('u_id',$v['user'])->value('tel');
                    }

                    $order[$k]['tel']=$tel;
                    $order[$k]['static']=$message;
                    $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                    $new_order[] = $order[$k];
                }


            }
            if($new_order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$new_order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //卖出已完成订单
    public function result_order_s(){
        $user = Request::instance()->param('u_id');
        if($user){
//            $order=Db::table('mb_sell_order')->where('type',2)->where('u_id',$user)->where('static',4)->order('time', 'desc')->select();

            $order=Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')
                ->where('mb_sell_order.type',2)
                ->where('mb_sell_order.u_id',$user)
                ->where('mb_sell_order.static',4)
                ->field('a.tel,w.money,w.s_id,w.static,w.time,w.u_id,w.user,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();


            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //卖出操作订单
    public function result_order_p(){
        $user = Request::instance()->param('u_id');
        if($user){

            $order=Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')

                ->where('mb_sell_order.type',1)
                ->where('mb_sell_order.user',$user)
//                ->where('mb_sell_order.static','>=',2)
                ->where('mb_sell_order.static','=',4)
                ->field('a.tel,w.money,w.s_id,w.static,w.time,w.u_id,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();


//            $order=Db::table('mb_sell_order')->where('type',1)->where('user',$user)->where('static','>=',2)->order('time', 'desc')->select();
//            Log::write($order,'notice');
            foreach($order as $k=>$v){
                switch ($v['static']) {
                    case 2:
                        $message = '交易中';
                        break;
                    case 3:
                        $message = '确认中';
                        break;
                    case 4:
                        $message = '已完成';
                        break;

                }
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $order[$k]['static']=$message;
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }

        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }
    }
    //卖出确认收款
    public function result_sell(){
        $user = Request::instance()->param('u_id');
        if($user){
            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.user')
                ->join('mb_bank c','w.user_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
                ->where('mb_sell_order.type',2)
                ->where('mb_sell_order.u_id',$user)
                ->where('mb_sell_order.static',3)
                ->field('a.u_img,a.user,c.way,a.tel,c.b_name,c.b_branch,w.money,w.shi_rmb,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();
			
            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }

                //添加银行卡信息
                $u_idBank = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('defult',1)->find();
                $u_idWx = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',2)->find();
                $u_idAli = Db::table('mb_bank')->where('u_id',$v['u_id'])->where('way',3)->find();
                $userBank = Db::table('mb_bank')->where('u_id',$v['user'])->where('defult',1)->find();
                $userWx = Db::table('mb_bank')->where('u_id',$v['user'])->where('way',2)->find();
                $userAli = Db::table('mb_bank')->where('u_id',$v['user'])->where('way',3)->find();

                $order[$k]['uid_c_name']=$u_idBank['c_name'];
                $order[$k]['uid_b_name']=$u_idBank['b_name'];
                $order[$k]['uid_b_card']=$u_idBank['b_card'];
                $order[$k]['uid_b_branch']=empty($u_idBank['b_branch']) ? "" : $u_idBank['b_branch'];
                $order[$k]['uid_wx_img']=$u_idWx['img'];
                $order[$k]['uid_ali_img']=$u_idAli['img'];

                $order[$k]['targetuid_c_name']=$userBank['c_name'];
                $order[$k]['targetuid_b_name']=$userBank['b_name'];
                $order[$k]['targetuid_b_card']=$userBank['b_card'];
                $order[$k]['targetuid_b_branch']=empty($userBank['b_branch']) ? "" : $userBank['b_branch'];    
                $order[$k]['targetuid_wx_img']=$userWx['img'];
                $order[$k]['targetuid_ali_img']=$userAli['img'];
				
                if($user == $v['user']){
                    $tel = Db::table('mb_user')->where('u_id',$v['u_id'])->value('tel');
                }else{
                    $tel = Db::table('mb_user')->where('u_id',$v['user'])->value('tel');
                }
                $order[$k]['tel']=$tel;
            }
			
			// return jsonp(['code' => 4, 'msg' => 'succeed','tel'=>$tel]);
            if($order){
			// var_dump($order);
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
				
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }
		
    }
    //买入确认收款
    public function result_sell_t(){
        $user = Request::instance()->param('u_id');
        if($user){
            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')
                ->join('mb_bank c','w.u_id_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
				
                ->where('mb_sell_order.type',1)
                ->where('mb_sell_order.user',$user)
                ->where('mb_sell_order.static',3)
                ->field('a.u_img,a.user,a.tel,c.b_name,c.b_branch,w.money,w.shi_rmb,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money')
                ->order('mb_sell_order.time', 'desc')
                ->select();
				
            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d H:i:s',$v['time']);
                $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }
                if($user == $v['user']){
                    $tel = Db::table('mb_user')->where('u_id',$v['u_id'])->value('tel');
                }else{
                    $tel = Db::table('mb_user')->where('u_id',$v['user'])->value('tel');
                }
				
                // $order[$k]['tel']=$tel;
				
            }
			// return jsonp(['code' => 4, 'msg' => 'succeed','data'=>$order]);
            if($order){
				
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }

        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }
    //卖出中心
    public function sell_sentic(){
        $money = Request::instance()->param('money');
        if($money){
            $order = Db::table('mb_user')
                ->alias('a')
                ->join('mb_sell_order w','a.u_id = w.u_id')
                ->join('mb_bank c','w.u_id_bank = c.b_id')
//                ->join('mb_bank_name n','c.b_name = n.bn_id')
                ->where('mb_sell_order.type',1)
                ->where('mb_sell_order.user',null)
                ->where('mb_sell_order.money',$money)
                ->field('a.u_img,a.user,a.tel,c.b_name,w.money,w.s_id,w.static,w.time,w.u_id,c.b_card,c.c_name,w.shi_money,w.shi_rmb')
                ->order('mb_sell_order.time', 'desc')
                ->select();
            foreach($order as $k=>$v){
                $order[$k]['time']=date('Y-m-d',$v['time']);
                $config45 = Db::table('mb_config')->where('co_id',45)->value('co_config');
                if(!$v['shi_rmb']){
                    $order[$k]['shi_rmb'] = $v['money']*$config45/100;
                }
            }
            if($order){
                return jsonp(['code' => 1, 'msg' => 'succeed','data'=>$order]);
            }else{
                return jsonp(['code' => 2, 'msg' => '暂无数据']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }


    }

    //确认打款中-取消订单
    public function cancel_order(){
        $u_id = Request::instance()->param('u_id');
//        $target_id = Request::instance()->param('target_id');
        $order_id = Request::instance()->param('order_id');
//        $money = Request::instance()->param('money');
        if($u_id && $order_id){
            $sell_order = Db::table('mb_sell_order')->where('s_id',$order_id)->find();
            
            if($sell_order['static'] != 2){
                return jsonp(['code' => 2, 'msg' => '订单操作错误！请重试']);
            }
            $data['user'] = null;
            $data['user_bank'] = null;
            $data['static'] = 1;
            $insert1 = Db::table('mb_sell_order')->where('s_id',$order_id)->setField($data);
            $insert2 = Db::table('mb_cancel_record')->insert([
                'u_id'=>$u_id,
                'target_id'=>$sell_order['user'],
                'money'=>$sell_order['money'],
                'order_id'=>$order_id,
                'type'=>1,
                'add_time'=>time(),
            ]);
            $user = Db::table("mb_user")->where('u_id',$sell_order['user'])->find();
            if($sell_order['type'] ==1 ){
                //挂的是买单   返还卖家的金额，买家照旧挂单
                $insert3 = Db::table('mb_user')->where('u_id',$sell_order['user'])->setInc('balance',$sell_order['money']);
                $insert4 = Db::table('mb_balance_order')->insert([
                    'u_id' => $sell_order['user'],
                    'bo_money' => $sell_order['money'],
                    'former_money' => $user['balance'],
                    'endmoney' => $user['balance']+$sell_order['money'],
                    'bo_time' => time(),
                    'type' => 37,   //
                    'xltype' => 37,   //
                    'target_uid' => $sell_order['user'],
                ]);
            }elseif ($sell_order['type'] ==2){
                //挂的是卖单  返还买家的保证金，卖家照旧挂单
                $insert3 = Db::table('mb_user')->where('u_id',$sell_order['user'])->setInc('balance',100);
                $insert4 = Db::table('mb_balance_order')->insert([
                    'u_id' => $sell_order['user'],
                    'bo_money' => 100,
                    'former_money' => $user['balance'],
                    'endmoney' => $user['balance']+100,
                    'bo_time' => time(),
                    'type' => 35,   //
                    'xltype' => 35,   //
                    'target_uid' => $sell_order['user'],
                ]);
            }

            if($insert1 && $insert2 && $insert3 && $insert4){
                return jsonp(['code' => 1, 'msg' => '取消成功']);
            }
        }else{
            return jsonp(['code' => 2, 'msg' => '参数错误']);
        }
    }

        
    //获取地址
    public function getaddress(&$arr) {

        $url = 'http://47.75.108.17/index/Newaccount';
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        $arr = curl_exec($ch); // 已经获取到内容，没有输出到页面上。
        curl_close($ch);

        $arr1 = substr($arr , 0 , 2);
//        var_dump($arr1);exit;
        // echo $arr1;
        // exit;
        if($arr1 != '0x'){
            return $this->getaddress($arr);
        }else{

            return $arr;
        }

    }




}
