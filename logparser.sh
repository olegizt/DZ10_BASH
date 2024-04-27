#!/bin/bash

#Зададим переменные
logfile="/weblogs/access-web.log"
logtimes="/logparser/parstimes.log"

#Проверка наличия файла с датами проверок. При отсутствии файла он создается с одной записью "1970-01-01T00:00:00"
if [ ! -f $logtimes ]; then
   echo "1970-01-01T00:00:00" > $logtimes
fi

#Последнюю запись файла (предыдущая обработка лога) записываем в переменную для последующего сравнения с поступающими данными
lastparstime=$(tail -n1 $logtimes )

#Преобразуем время предыдущего запуска парсера в секунды от 1970-01-01 00:00:00 UTC
lastparstimesec=$(date -d $lastparstime +%s)

#Запишем дату_время текущего запуска в переменную и добавим в файл лога времени запуска
curparstime=$(date +%F"T"%T) && echo "$curparstime" >> $logtimes

#замена формата даты в исходном лог-файле (14/Aug/2019:04:12:10) на представление в секундах от 1970-01-01 00:00:00 UTC и вывод строк лога с датами больше, чем дата предыдущего запуска скрипта в переменную
parstimelog=$(
cat $logfile |
sed 's/\[//;s/\//-/;s/\//-/;s/\:/T/' |
awk '{cmd="date -d "$4" +%s"; cmd | getline x; close(cmd);$4=x;print $0}' |
awk -v tmpvar=$lastparstimesec '$4 > tmpvar {print}')

#Формирование тела письма с указанием необходимых данных. Если с момента последнего парсинга новых данных нет, текст письма об этом укажет
if [ $(echo "$parstimelog" | wc -l) -gt 0 ] && [ -n "$(echo "$parstimelog" | grep -v '^$')" ]; then
    mailbody=$(
    printf '.%.0s' {1..80}; echo
	echo "Лог сформирован за период с" $lastparstime "до" $curparstime
    printf '.%.0s' {1..80}; echo
    echo "Список IP адресов (с наибольшим кол-вом запросов) - топ 10"
    echo "$parstimelog" | cut -f 1 -d ' ' | sort | uniq -c | sort -n -r | sed -n "1,10 p" 
    printf '.%.0s' {1..80}; echo
    echo "Список запрашиваемых URL (с наибольшим кол-вом запросов) - топ 10"
    echo "$parstimelog" | cut -f 11 -d ' ' | sort | uniq -c | sort -n -r | sed -n "1,10 p" 
    printf '.%.0s' {1..80}; echo
    echo "Список всех кодов HTTP ответа"
    echo "$parstimelog" | cut -f 9 -d ' ' | sort | uniq -c | sort -n -r
    printf '.%.0s' {1..80}; echo
    echo "Ошибки веб-сервера/приложения"
    echo "$parstimelog" | awk '$9 ~ /^5/ {print $0}' 
	printf '.%.0s' {1..80}; echo)
else
    mailbody=$(
    printf '.%.0s' {1..80}; echo
    echo "За период с" $lastparstime "до" $curparstime "новых данных не поступало"
    printf '.%.0s' {1..80}; echo)
fi

#Отправка письма, локально, т.к. для отправки на реальную почту необходимо или указывать личные данные для аутентификации на публичном почтовике, или делать свой почтовый сервер с занесением данных в публичный DNS
echo "$mailbody" | mailx -s "Log from $curparstime" root@localhost

