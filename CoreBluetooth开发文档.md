CoreBluetooth开发文档
========================

[TOC]

## 介绍
语言:Swift 3.0
开发平台: Xcode 7.1

## 框架
### 结构体
### 方法

## 开发方法

### 初始化

1. 建立中心角色

### 搜索外设

2. 扫描外设（discover）

### 建立链接和断开链接

3. 连接外设(connect)

### 扫描服务和特征

4. 扫描外设中的服务和特征(discover)

 - 4.1 获取外设的services

 - 4.2 获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值

### 读取数据

#### Read方式

#### Notify方式
 
### 写入数据

#### Write方式

#### Write Without Response方式



## 自定义辅助函数

### 权限显示函数

### TextField滚动显示函数

## 实例

### 完整读取(Notify)

### 完整写入(Write)

## 常见问题
整理了自己遇见的和StackOverflow里常见的问题。  

1. 调用CBCentralManager.connect函数后，didConnect无响应
>检查CBCentralManager是否已经绑定了delegate 即  
>var myCentralManager: CBCentralManager!  
>myCentralManager.delegate = self

2. 

## 引用文档
官方蓝牙开发指南: https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html#//apple_ref/doc/uid/TP40013257 
官方API: https://developer.apple.com/reference/corebluetooth 

