CREATE DATABASE football_management;
use football_management;
CREATE TABLE Teams(
	team_id INT PRIMARY KEY AUTO_INCREMENT,
    team_name VARCHAR(100) NOT NULL,
    founded_year INT NOT NULL,
    stadium VARCHAR(100) NOT NULL,
    ranking_position INT DEFAULT 0
);
CREATE TABLE Coaches(
	coach_id INT PRIMARY KEY AUTO_INCREMENT,
	full_name VARCHAR(100) NOT NULL,
    nationality VARCHAR(50) NOT NULL,
	experience_years INT DEFAULT 0,
	team_id INT,
	FOREIGN KEY(team_id) REFERENCES Teams(team_id)
);
CREATE TABLE Players(
	player_id INT PRIMARY KEY AUTO_INCREMENT,
	full_name VARCHAR(100) NOT NULL,
	jersey_number INT NOT NULL,
	position VARCHAR(50) NOT NULL,
	salary DECIMAL(12,2) NOT NULL,
	team_id INT,
	foreign key (team_id) references Teams(team_id)
);
CREATE TABLE Matches(
	match_id INT PRIMARY KEY AUTO_INCREMENT,
	home_team_id INT,
	FOREIGN KEY (home_team_id) REFERENCES Teams(team_id),
	away_team_id INT,
	FOREIGN KEY (home_team_id) REFERENCES Teams(team_id),
	match_date DATETIME not null,
	stadium VARCHAR(100) not null,
	match_status VARCHAR(30) DEFAULT 'Scheduled'
);
CREATE TABLE Player_Statistics(
	stat_id INT PRIMARY KEY AUTO_INCREMENT,
    player_id	INT,
    FOREIGN KEY (player_id) REFERENCES Players(player_id),
	match_id	INT,
    FOREIGN KEY(match_id) REFERENCES Matches(match_id),
	goals	INT DEFAULT 0,
	assists	INT DEFAULT 0,
	yellow_cards	INT DEFAULT 0,
	rating_score	DECIMAL(3,1) DEFAULT 0
);
CREATE TABLE transfer_history(
	transfer_id INT PRIMARY KEY AUTO_INCREMENT,
	player_id INT,
    FOREIGN KEY(player_id) REFERENCES Players(player_id),
    team_id INT,
	foreign key (team_id) references Teams(team_id),
    transfer_date DATE
);
INSERT INTO Teams(team_id,team_name,founded_year,stadium,ranking_position)
VALUES
(1,"Manchester City","1880","Etihad Stadium",1),
(2,"Real Madrid","1902","Santiago Bernabeu",2),
(3,"Hanoi FC","2006","Hang Day Stadium",3),
(4,"Saigon United","2015","Thong Nhat Stadium",5),
(5,"Thép xanh Nam Định","1979","Thiên Trường Stadium",10);

INSERT INTO Coaches(coach_id,full_name,nationality,experience_years,team_id)
VALUES
(1,"Pep Guardiola","Spanish",15,1),
(2,"Carlo Ancelotti","Italian",25,2),
(3," Chu Đình Nghiêm","Vietnamese",12,3),
(4," Alexandre Polking","German-Brazilian",10,4),
(5,"Park Hang-seo","Korean",30,5);

INSERT INTO Players(player_id,full_name,jersey_number,position,salary,team_id)
VALUES
(1,"Erling Haaland",9,"Forward","450000000",1),
(2,"Kevin De Bruyne",17,"Midfielder","400000000",1),
(3,"Nguyễn Quang Hải",19,"Midfielder","60000000",3),
(4,"Kylian Mbappe",7,"Forward","500000000",2),
(5,"Nguyễn Văn Quyết",10,"Forward","55000000",3);

INSERT INTO Matches(match_id,home_team_id,away_team_id,match_date,stadium,match_status)
VALUES
(1,1,2,"2026-05-10 19:00","Etihad Stadium","Finished"),
(2,3,4,"2026-05-12 18:30","Hang Day Stadium","Finished"),
(3,5,1,"2026-05-15 20:00","Thien Truong Stadium","Scheduled"),
(4,2,3,"2026-05-20 21:00","Santiago Bernabeu","Scheduled"),
(5,4,5,"2026-05-25 17:00","Thong Nhat Stadium","Scheduled");

INSERT INTO Player_Statistics(stat_id,player_id,match_id,goals,assists,yellow_cards,rating_score)
VALUES
(1,1,1,2,1,0,9.5),
(2,4,1,1,0,1,8.2),
(3,3,2,0,2,0,8.5),
(4,5,2,3,0,0,9.0),
(5,1,4,0,0,3,5.0);

UPDATE  Players p
JOIN Player_Statistics ps ON p.player_id=ps.player_id
SET p.salary=p.salary*1.15
WHERE p.position='Forward' AND ps.rating_score>8.0;

DELETE FROM Player_Statistics
WHERE yellow_cards>2;

SELECT full_name,jersey_number,position FROM Players
WHERE salary> 50000000 OR position='Midfielder';

SELECT team_name,stadium FROM Teams
WHERE stadium LIKE'S%' OR ranking_position BETWEEN 1 AND 5;

SELECT match_id,stadium,match_date FROM Matches
ORDER BY match_date DESC 
LIMIT 3 OFFSET 2;

SELECT p.full_name,t.team_name,ps.goals,ps.assists FROM Players p
LEFT JOIN Player_Statistics ps ON p.player_id=ps.player_id
LEFT JOIN Teams t ON t.team_id=p.team_id;

SELECT t.team_name,SUM(ps.goals) as 'Tong so ban thang' FROM Teams t
JOIN Players p ON t.team_id=p.team_id
JOIN Player_Statistics ps ON ps.player_id=p.player_id
GROUP BY t.team_name;

SELECT player_id,full_name,salary FROM Players p
WHERE salary>=(SELECT MAX(salary) FROM Players)
LIMIT 1;

CREATE INDEX idx_search_players ON Players(position,salary);

CREATE OR REPLACE VIEW view_overall_teams AS
	SELECT t.team_name,COUNT(p.player_id) as'Tong cau thu',SUM(p.salary) as 'Tong quy luong' FROM Players p
    JOIN Teams t ON t.team_id=p.team_id
    GROUP BY t.team_name;
    
SELECT * FROM view_overall_teams;

DELIMITER // 
CREATE TRIGGER update_salary
AFTER INSERT ON  player_statistics
FOR EACH ROW
BEGIN
	DECLARE v_salary DECIMAL(12,2); 
    SELECT saly INTO v_salary FROM Players;
	IF NEWar.goals>10 THEN SET v_salary=v_salary*1.05;
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE check_goals(IN p_player_id INT,OUT p_thong_bao VARCHAR(200))
BEGIN
	DECLARE total_goals INT;
    select SUM(ps.goals) INTO total_goals FROM Player_Statistics ps
    where p_player_id=ps.player_id;
    
    if total_goals>20 then set p_thong_bao='Excellent';
    elseif total_goals between 10 and 20 then set p_thong_bao='Good';
    else set p_thong_bao='Average';
    end if;
END //
DELIMITER ;

DELIMITER //
	CREATE PROCEDURE transfer_players(IN p_player_id INT )
    begin
    DECLARE v_team_id VARCHAR(100);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    begin
    ROLLBACK;
    end;
    START TRANSACTION;
    SELECT team_id INTO v_team_id FROM Teams;
    UPDATE Players
    SET team_id=v_team_id
    WHERE p_player_id=player_id;
    INSERT INTO transfer_history
    VALUES(p_player_id,v_team_id,NOW());
    COMMIT;
    end//
DELIMITER ;
